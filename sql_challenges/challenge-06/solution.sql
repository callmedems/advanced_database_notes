-- 1
CREATE OR REPLACE TRIGGER trg_pet_care_log_insert
BEFORE INSERT ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    :NEW.LAST_UPDATE_DATETIME := SYSDATE;
    :NEW.CREATED_BY_USER := USER;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Insert failed.');
END;

-- 2
CREATE OR REPLACE TRIGGER trg_pet_care_log_update
BEFORE UPDATE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    IF USER != :OLD.CREATED_BY_USER THEN
        RAISE_APPLICATION_ERROR(-20002, 'You can only update records you created.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- We re-raise the specific error message if it's the one we just triggered
        IF SQLCODE = -20002 THEN RAISE; END IF; 
        RAISE_APPLICATION_ERROR(-20003, 'Update failed.');
END;

-- 3 
CREATE OR REPLACE TRIGGER trg_pet_care_log_delete
BEFORE DELETE ON PET_CARE_LOG
FOR EACH ROW
BEGIN
    IF USER != 'JOEMANAGER' THEN
        RAISE_APPLICATION_ERROR(-20004, 'Only JOEMANAGER can delete records.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -20004 THEN RAISE; END IF;
        RAISE_APPLICATION_ERROR(-20005, 'Delete failed.');
END;