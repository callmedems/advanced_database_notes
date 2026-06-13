# ============================================================
# EXERCISE 1 — Model Design
# ============================================================
from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, func, CheckConstraint
from sqlalchemy.orm import relationship

# 1. The Comment Model
class Comment(Base):
    __tablename__ = "comments"
    
    id = Column(Integer, primary_key=True)
    task_id = Column(Integer, ForeignKey("tasks.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Bonus applied here: Check constraint so content != ''
    content = Column(Text, CheckConstraint("content != ''"), nullable=False)
    created_at = Column(DateTime, server_default=func.current_timestamp())

    # Relationships back to the parent tables
    task = relationship("Task", back_populates="comments")
    user = relationship("User", back_populates="comments")
'''
Answers to Ex 1 Questions:
1. Relationships: It needs a 'task' relationship (to Task) and a 'user' relationship (to User).
2. Task relationship: Yes, Task should have a 'comments' relationship to easily fetch all comments on a task.
3. Deletion: If a task is deleted, the comments should be deleted too (this is done using cascade="all, delete-orphan" on the Task model).
'''

# ============================================================
# EXERCISE 2 — Migration Creation
# ============================================================
'''
Answers to Ex 2 Questions:
1. upgrade(): This function contains the Alembic commands to apply the new changes (e.g., op.create_table('comments')).
2. downgrade(): This function contains the exact opposite commands to undo the changes (e.g., op.drop_table('comments')).
3. If downgraded: The comments table is dropped from the database, and ALL data inside it is permanently lost.
'''

# ============================================================
# EXERCISE 3 — CRUD Challenge
# ============================================================
# Assuming 'session' is your active SQLAlchemy Session object

# 1 & 2. Create team and user
devops = Team(name="DevOps", description="Infrastructure and Deployment")
session.add(devops)
session.flush() # Flushes to get the devops.id if needed, but ORM handles it

diana = User(username="diana_ops", email="diana@example.com", full_name="Diana Prince", team=devops)
session.add(diana)

# 3. Create 3 tasks with different priorities
t1 = Task(title="Set up CI/CD pipeline", priority="high", assignee=diana)
t2 = Task(title="Monitor production logs", priority="medium", assignee=diana)
t3 = Task(title="Update architecture docs", priority="low", assignee=diana)
session.add_all([t1, t2, t3])
session.commit()

# 4. Print task count
task_count = session.query(Task).count()
print(f"Total tasks in database: {task_count}")

# 5. Close one task
t1.status = "closed"
session.commit()
print(f"Closed task: {t1.title}")

# 6. Delete the lowest priority task
lowest_task = session.query(Task).filter_by(priority="low").first()
if lowest_task:
    session.delete(lowest_task)
    session.commit()
    print("Deleted lowest priority task.")

# ============================================================
# EXERCISE 4 — Migration Rollback
# ============================================================
'''
Answers to Ex 4 Questions:
1. Column: The `estimated_hours` column is completely dropped from the schema.
2. Data: Any hour estimates that were saved in that column for existing tasks are permanently erased.
'''

# ============================================================
# EXERCISE 5 — Concept Check
# ============================================================
'''
Answers to Ex 5 Questions:
1. Why ORM?: It prevents SQL injection, abstracts database dialects (so switching from Oracle to PostgreSQL is easy), and lets you write native object-oriented Python code instead of messy string concatenations.
2. Why migrations?: They act as version control (like Git) for your database schema, allowing you to track changes, collaborate safely, and deploy updates reliably.
3. When to rollback?: When a migration breaks production, introduces a bug, or when you are testing schema changes locally and want to revert to a clean slate.
4. add() vs commit()?: `add()` just puts the object into the Session (in memory). `commit()` actually fires the INSERT/UPDATE SQL commands to save it to the physical database.
5. Why relationships?: They allow you to traverse related data automatically (like `user.team.name`) without having to manually write complex SQL JOIN queries.
'''