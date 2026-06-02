-- insert trigger
CREATE OR REPLACE TRIGGER trg_petcare_insert
BEFORE INSERT ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    -- Using the pseudocolumns SYSDATE for time and USER for the current session user
    :NEW.UPDATE_DATE := SYSDATE;
    :NEW.UPDATED_BY_USER := USER;
EXCEPTION
    WHEN OTHERS THEN
        -- Catch-all for database errors during insert
        RAISE_APPLICATION_ERROR(-20001, 'Unexpected error during insert: ' || SQLERRM);
END;
/

-- the update trigger
CREATE OR REPLACE TRIGGER trg_petcare_update
BEFORE UPDATE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    -- Compare the current session user with the old record's user
    IF USER != :OLD.UPDATED_BY_USER THEN
        RAISE_APPLICATION_ERROR(-20002, 'Update denied: You can only modify your own records.');
    END IF;
    
    -- It's also standard practice to refresh the timestamp when an update occurs!
    :NEW.UPDATE_DATE := SYSDATE;
    
EXCEPTION
    WHEN OTHERS THEN
        -- We check if it's our custom error (-20002) so we don't accidentally overwrite our own message
        IF SQLCODE = -20002 THEN 
            RAISE; 
        ELSE
            RAISE_APPLICATION_ERROR(-20003, 'Unexpected error during update: ' || SQLERRM);
        END IF;
END;
/

-- delete trigger
CREATE OR REPLACE TRIGGER trg_petcare_delete
BEFORE DELETE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    -- Strict check for the manager account
    IF USER != 'JOEMANAGER' THEN
        RAISE_APPLICATION_ERROR(-20004, 'Delete denied: Only JOEMANAGER can delete log entries.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Again, letting our custom error pass through while catching unexpected ones
        IF SQLCODE = -20004 THEN 
            RAISE; 
        ELSE
            RAISE_APPLICATION_ERROR(-20005, 'Unexpected error during delete: ' || SQLERRM);
        END IF;
END;
/