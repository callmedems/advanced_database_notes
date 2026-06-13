-- ============================================================
-- PART A: The KPI Contract (Conceptual)
-- ============================================================

-- ============================================================
-- EXERCISE 1: Define "Team Velocity"
-- ============================================================
/*
1. Business question: How fast does each team complete work?
2. Definition: The total count of tasks with status = 'completed', grouped by team. 
3. Edge cases: Excludes cancelled tasks. Does not currently normalize by team size (which favors larger teams like Engineering over Product).
4. Unit: Task count.
5. Misleading if: A team closes 50 easy 'low' priority tasks while another closes 5 complex 'critical' tasks. Velocity looks higher for the first team.
*/
WITH TeamStats AS (
    SELECT t.name AS team_name,
           COUNT(ts.id) AS completed_velocity
    FROM teams t
    LEFT JOIN users u ON u.team_id = t.id
    LEFT JOIN tasks ts ON ts.assigned_to = u.id AND ts.status = 'completed'
    GROUP BY t.id, t.name
),
OverallAvg AS (
    SELECT AVG(completed_velocity) AS avg_vel FROM TeamStats
)
SELECT s.team_name,
       s.completed_velocity,
       CASE WHEN s.completed_velocity < a.avg_vel THEN 'Below Average'
            ELSE 'Above/On Average' END AS performance_flag
FROM TeamStats s
CROSS JOIN OverallAvg a
ORDER BY s.completed_velocity DESC;


-- ============================================================
-- EXERCISE 2: Define "On-Time Delivery Rate"
-- ============================================================
/*
1. Business question: Do we meet our deadlines?
2. Definition: Percentage of completed tasks where completed_at is less than or equal to due_date + 1 (end of day).
3. Edge cases: Tasks with NULL due dates are excluded from the calculation.
4. Unit: Percentage (%).
5. Misleading if: Due dates are constantly shifted backwards to avoid being flagged as late.
*/
SELECT priority,
       COUNT(*) AS total_completed_with_due_date,
       ROUND(
           SUM(CASE WHEN TRUNC(completed_at) <= due_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
       1) AS on_time_rate_pct,
       ROUND(
           AVG(CASE WHEN TRUNC(completed_at) > due_date 
                    THEN EXTRACT(DAY FROM (completed_at - CAST(due_date AS TIMESTAMP))) * 24 
                    ELSE NULL END), 
       1) AS avg_lateness_hours
FROM tasks
WHERE status = 'completed' AND due_date IS NOT NULL
GROUP BY priority;


-- ============================================================
-- PART B: Improve the Class KPIs
-- ============================================================

-- ============================================================
-- EXERCISE 3: Improve "Tasks per Team" 
-- ============================================================
SELECT t.name AS team_name,
       COUNT(ts.id) AS total_tasks,
       COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 END) AS active_tasks,
       ROUND(
           COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) * 100.0 / 
           NULLIF(COUNT(CASE WHEN ts.status != 'cancelled' THEN 1 END), 0), 
       1) AS completion_rate,
       CASE 
           WHEN COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 END) > 10 THEN 'Overloaded'
           WHEN COUNT(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 END) BETWEEN 5 AND 10 THEN 'Healthy'
           ELSE 'Underutilized'
       END AS health_score
FROM teams t
LEFT JOIN users u ON u.team_id = t.id
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY t.id, t.name
ORDER BY active_tasks DESC;


-- ============================================================
-- EXERCISE 4: Improve "Average Resolution Time" 
-- ============================================================
SELECT priority,
       COUNT(*) AS completed_task_count,
       ROUND(AVG(
           EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
           EXTRACT(HOUR FROM (completed_at - created_at))
       ), 1) AS avg_res_hours,
       ROUND(MEDIAN(
           EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
           EXTRACT(HOUR FROM (completed_at - created_at))
       ), 1) AS median_res_hours,
       CASE priority
           WHEN 'critical' THEN CASE WHEN AVG(EXTRACT(DAY FROM (completed_at - created_at)) * 24) <= 24 THEN 'Met' ELSE 'Failed' END
           WHEN 'high'     THEN CASE WHEN AVG(EXTRACT(DAY FROM (completed_at - created_at)) * 24) <= 72 THEN 'Met' ELSE 'Failed' END
           WHEN 'medium'   THEN CASE WHEN AVG(EXTRACT(DAY FROM (completed_at - created_at)) * 24) <= 168 THEN 'Met' ELSE 'Failed' END
           WHEN 'low'      THEN CASE WHEN AVG(EXTRACT(DAY FROM (completed_at - created_at)) * 24) <= 336 THEN 'Met' ELSE 'Failed' END
       END AS sla_target_met
FROM tasks
WHERE status = 'completed' AND completed_at IS NOT NULL
GROUP BY priority;


-- ============================================================
-- EXERCISE 5: Improve "Overdue Tasks"
-- ============================================================
SELECT ts.title,
       u.full_name AS assignee,
       t.name AS team,
       ts.priority,
       ts.due_date,
       TRUNC(SYSDATE) - ts.due_date AS days_overdue,
       CASE 
           WHEN ts.priority = 'critical' AND (TRUNC(SYSDATE) - ts.due_date) > 0 THEN 'CRITICAL'
           WHEN ts.priority = 'high' AND (TRUNC(SYSDATE) - ts.due_date) > 2 THEN 'HIGH'
           WHEN ts.priority = 'medium' AND (TRUNC(SYSDATE) - ts.due_date) > 5 THEN 'MEDIUM'
           ELSE 'LOW'
       END AS severity
FROM tasks ts
LEFT JOIN users u ON ts.assigned_to = u.id
LEFT JOIN teams t ON u.team_id = t.id
WHERE ts.due_date < TRUNC(SYSDATE)
  AND ts.status NOT IN ('completed', 'cancelled')
ORDER BY 
    CASE severity WHEN 'CRITICAL' THEN 1 WHEN 'HIGH' THEN 2 WHEN 'MEDIUM' THEN 3 ELSE 4 END,
    days_overdue DESC;


-- ============================================================
-- PART C: The "Bad KPI" Challenge
-- ============================================================

-- ============================================================
-- EXERCISE 6: Fix the "Productivity Score"
-- ============================================================
/*
PROBLEM: It counts ALL tasks assigned to a user, meaning a user with 50 'open' tasks looks more productive than a user with 5 'completed' tasks. It doesn't measure actual output.
REWRITE: Count completed tasks, weighted by priority to account for complexity.
*/
SELECT u.full_name,
       SUM(CASE priority
           WHEN 'critical' THEN 4
           WHEN 'high' THEN 3
           WHEN 'medium' THEN 2
           WHEN 'low' THEN 1
           ELSE 0 END) AS weighted_productivity_score
FROM users u
JOIN tasks ts ON ts.assigned_to = u.id
WHERE ts.status = 'completed'
GROUP BY u.id, u.full_name
ORDER BY weighted_productivity_score DESC;


-- ============================================================
-- EXERCISE 7: Fix the "Team Efficiency"
-- ============================================================
/*
PROBLEM: Averaging the Task ID (Primary Key) is mathematically meaningless. A task with ID 9999 isn't "better" than ID 1.
REWRITE: Measure efficiency as the ratio of completed tasks to total assigned tasks per team.
*/
SELECT t.name AS team_name,
       COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) AS completed_tasks,
       COUNT(ts.id) AS total_tasks,
       ROUND(COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) * 100.0 / NULLIF(COUNT(ts.id), 0), 1) AS efficiency_pct
FROM teams t
LEFT JOIN users u ON u.team_id = t.id
LEFT JOIN tasks ts ON ts.assigned_to = u.id
GROUP BY t.id, t.name
ORDER BY efficiency_pct DESC;


-- ============================================================
-- EXERCISE 8: Fix the "Urgency Index"
-- ============================================================
/*
PROBLEM: You cannot multiply a VARCHAR ('high') by a number, nor can you add a string directly to a DATE object in a meaningful way.
REWRITE: Assign a numeric weight to the priority, and add the number of days overdue.
*/
SELECT title,
       status,
       priority,
       due_date,
       (CASE priority
           WHEN 'critical' THEN 40
           WHEN 'high' THEN 30
           WHEN 'medium' THEN 20
           WHEN 'low' THEN 10
           ELSE 0 END) + (TRUNC(SYSDATE) - due_date) AS real_urgency_score
FROM tasks
WHERE status NOT IN ('completed', 'cancelled')
ORDER BY real_urgency_score DESC;