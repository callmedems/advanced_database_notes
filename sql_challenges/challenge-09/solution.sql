-- ============================================================
-- Lesson 04: Class Exercises - Solutions
-- ============================================================

-- ============================================================
-- EXERCISE 1: Manual transaction (warm-up)
-- ============================================================
-- Transfer $50 from Charlie (3) to Alice (1)
BEGIN
    UPDATE accounts SET balance = balance - 50 WHERE account_id = 3;
    UPDATE accounts SET balance = balance + 50 WHERE account_id = 1;
    COMMIT;
END;
/
-- Verify: Alice should be 1050, Charlie should be 200
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;


-- ============================================================
-- EXERCISE 2: Catch yourself with ROLLBACK
-- ============================================================
BEGIN
    -- Attempt the massive transfer
    UPDATE accounts SET balance = balance - 10000 WHERE account_id = 2;
    UPDATE accounts SET balance = balance + 10000 WHERE account_id = 3;
    
    -- At this point, the transaction is pending. 
    -- If we SELECT balance right now, we would see negative balances,
    -- or hit the CHECK constraint if it's evaluated immediately.
    
    -- Uh oh, Bob doesn't have 10k! Undo everything!
    ROLLBACK;
END;
/
-- Verify: Bob should still be 500, Charlie should be 200
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;


-- ============================================================
-- EXERCISE 3: SAVEPOINT checkpoint
-- ============================================================
BEGIN
    -- 1. Add $25 to Alice's balance
    UPDATE accounts SET balance = balance + 25 WHERE account_id = 1;
    
    -- 2. Set a savepoint
    SAVEPOINT alice_deposited;
    
    -- 3. Deduct $25 from Charlie (accident!)
    UPDATE accounts SET balance = balance - 25 WHERE account_id = 3;
    
    -- 4. Rollback to savepoint (undoes Charlie's deduction, keeps Alice's addition)
    ROLLBACK TO SAVEPOINT alice_deposited;
    
    -- 5. Deduct $25 from Bob instead
    UPDATE accounts SET balance = balance - 25 WHERE account_id = 2;
    
    -- 6. Commit the final state
    COMMIT;
END;
/
-- Verify: Alice=1075, Bob=475, Charlie=200
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;


-- ============================================================
-- EXERCISE 4: Write your own stored procedure
-- ============================================================
CREATE OR REPLACE PROCEDURE deposit_funds(
    p_account_id IN NUMBER,
    p_amount     IN NUMBER
) AS
BEGIN
    -- 1. Validate amount is positive
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Deposit amount must be greater than zero.');
    END IF;

    -- 2. Add amount to balance
    UPDATE accounts 
    SET balance = balance + p_amount 
    WHERE account_id = p_account_id;

    -- 3. Commit on success
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully deposited $' || p_amount || ' into account ' || p_account_id);

EXCEPTION
    WHEN OTHERS THEN
        -- 4. Rollback and re-raise on error
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Deposit failed: ' || SQLERRM);
        RAISE;
END;
/

-- Test it:
SET SERVEROUTPUT ON;
EXEC deposit_funds(3, 75);
-- Verify: Charlie should now have 275
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;


-- ============================================================
-- EXERCISE 5: Discussion
/*
Answers:

Q1: Appointment booking system
- Inside the transaction: (a) Reserve time slot and (b) Create appointment record.
  These two actions MUST succeed or fail together to maintain data integrity 
  (you don't want a reserved slot with no record, or a record for an unreserved slot).
- Outside the transaction: (c) Send confirmation notification. 
  Never put external system calls (like sending emails) inside a database transaction. 
  If the email server is slow, your database tables stay locked. Also, if the transaction 
  rolls back AFTER the email is sent, the patient gets an email for an appointment that 
  doesn't exist!

Q2: Developer calling a COMMIT-heavy procedure
- The problem is "Transaction Fragmentation" or breaking the developer's atomicity. 
  If the developer calls your procedure, your COMMIT finalizes NOT ONLY your code, 
  but ALL pending changes the developer made up to that point. If the developer's 
  larger process fails later, they can no longer roll back the work done before your 
  procedure was called. (This is why many DBAs argue that COMMITs should usually be 
  handled by the application layer, not inside stored procedures).

Q3: Functions vs Procedures in SELECT
- Can they use calculate_copay() in a SELECT? YES. Because it is a FUNCTION 
  and returns a value without modifying state, it is perfectly safe to use inline.
- Can they use post_payment() in a SELECT? NO. It is a PROCEDURE. Procedures execute 
  actions (DML statements like INSERT/UPDATE/DELETE) and do not return a single scalar 
  value. Attempting to use a procedure in a SELECT will throw an Oracle error.
*/