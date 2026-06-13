-- ============================================================
-- Lesson 08: Class Exercises - Assignment History
-- ============================================================

-- ============================================================
-- Step 1 — Source Tables (OLTP)
-- ============================================================
-- Agents table (implicitly needed to represent users/agents)
CREATE TABLE agents (
    agent_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(100),
    team VARCHAR2(50)
);

CREATE TABLE tickets (
    ticket_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR2(200) NOT NULL,
    status VARCHAR2(20) DEFAULT 'open',
    priority VARCHAR2(20) DEFAULT 'medium',
    assigned_to NUMBER REFERENCES agents(agent_id),
    created_at TIMESTAMP DEFAULT SYSTIMESTAMP,
    resolved_at TIMESTAMP
);

CREATE TABLE ticket_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id NUMBER REFERENCES tickets(ticket_id),
    assigned_to NUMBER REFERENCES agents(agent_id),
    assigned_by NUMBER REFERENCES agents(agent_id),
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP
);

-- ============================================================
-- Step 3 — Trigger (Created BEFORE data to capture initial inserts)
-- ============================================================
CREATE OR REPLACE TRIGGER trg_ticket_assignment_log
    AFTER INSERT OR UPDATE OF assigned_to ON tickets
    FOR EACH ROW
BEGIN
    IF INSERTING THEN
        -- Log initial assignment
        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, NULL, :NEW.created_at);
    ELSIF UPDATING THEN

        UPDATE ticket_assignments
           SET valid_to = :NEW.created_at -- Simplification: Using SYSTIMESTAMP or updated_at in real life
         WHERE ticket_id = :OLD.ticket_id
           AND valid_to IS NULL;
           

        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, NULL, SYSTIMESTAMP);
    END IF;
END;
/

-- ============================================================
-- Step 2 — Sample Data
-- ============================================================
INSERT INTO agents (name, team) VALUES ('Alice', 'Support L1');
INSERT INTO agents (name, team) VALUES ('Bob', 'Support L2');
INSERT INTO agents (name, team) VALUES ('Charlie', 'Billing');

INSERT INTO tickets (title, status, priority, assigned_to, created_at) 
VALUES ('Password reset failed', 'open', 'high', 1, TIMESTAMP '2026-06-01 10:00:00');
INSERT INTO tickets (title, status, priority, assigned_to, created_at) 
VALUES ('Cannot update payment', 'open', 'medium', 3, TIMESTAMP '2026-06-02 11:00:00');
INSERT INTO tickets (title, status, priority, assigned_to, created_at) 
VALUES ('App crashes on launch', 'open', 'critical', 1, TIMESTAMP '2026-06-03 09:00:00');

COMMIT;

-- TEST 
UPDATE tickets 
SET assigned_to = 2, 
    status = 'resolved', 
    resolved_at = TIMESTAMP '2026-06-04 15:00:00' 
WHERE ticket_id = 3;
COMMIT;

SELECT * FROM ticket_assignments WHERE ticket_id = 3 ORDER BY valid_from;

-- ============================================================
-- Step 4 — Data Warehouse Tables (Star Schema)
-- ============================================================
CREATE TABLE dim_agent (
    agent_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_id NUMBER NOT NULL, -- Source system ID
    agent_name VARCHAR2(100),
    team VARCHAR2(50)
);

CREATE TABLE fact_ticket_daily (
    fact_key NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key NUMBER NOT NULL, -- YYYYMMDD
    agent_key NUMBER REFERENCES dim_agent(agent_key),
    status VARCHAR2(20),
    priority VARCHAR2(20),
    tickets_created NUMBER DEFAULT 0,
    tickets_resolved NUMBER DEFAULT 0
);

-- ============================================================
-- Step 5 — Populate dim_agent
-- ============================================================
INSERT INTO dim_agent (agent_id, agent_name, team) 
SELECT agent_id, name, team FROM agents;
COMMIT;
