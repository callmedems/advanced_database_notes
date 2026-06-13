-- ============================================================
-- Lesson 05: Schema Backup & Restore - Solutions
-- ============================================================

-- ============================================
-- EXERCISE 1: Explore your schema
-- ============================================
-- Group by object_type and count them
SELECT object_type, COUNT(*) AS cnt
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

-- Get detailed list of objects
SELECT object_name, object_type, created, last_ddl_time
FROM user_objects
ORDER BY object_type, object_name;


-- ============================================
-- EXERCISE 2: Basic GET_DDL
-- ============================================
-- First, set transform params for clean output:
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

SET LONG 100000
SET PAGESIZE 0

-- Get DDL for a specific table (Using 'ACCOUNTS' from Lesson 04)
SELECT DBMS_METADATA.GET_DDL('TABLE', 'ACCOUNTS') FROM DUAL;

-- Get all tables at once
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
ORDER BY table_name;


-- ============================================
-- EXERCISE 3: Clean DDL for portability
-- ============================================
-- Remove schema names from DDL so it works in any schema
BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'EMIT_SCHEMA', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', true);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', false);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', false);
END;
/

-- Test it: Notice the output no longer has "YOUR_SCHEMA"."TABLE_NAME"
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name)
FROM user_tables
WHERE ROWNUM = 1;


-- ============================================
-- EXERCISE 4: Plan a migration
-- ============================================
/* Migration Checklist (SCHEMA_OLD to SCHEMA_NEW):
  [x] Export all DDL with EMIT_SCHEMA = false
  [x] Review FK constraints for schema references using the query below
  [x] Update constraint references to point to SCHEMA_NEW (if necessary)
  [x] Reload in order: tables -> constraints -> indexes -> views -> code
*/

-- Check for schema-qualified references in Foreign Keys:
SELECT constraint_name, table_name, r_constraint_name
FROM user_constraints
WHERE constraint_type = 'R';


-- ============================================
-- EXERCISE 5: Dependency order
-- ============================================
-- See all dependencies in your schema:
SELECT referenced_name, referencing_name, referencing_type
FROM user_dependencies
ORDER BY referenced_name;

-- Find objects that depend on TABLES (to know what needs tables first):
SELECT referencing_name, referencing_type
FROM user_dependencies
WHERE referenced_name IN (
  SELECT table_name FROM user_tables
)
ORDER BY referencing_type, referencing_name;

-- Build a dependency tree for PL/SQL objects (Procedures/Functions):
SELECT referencing_name, referencing_type,
       LISTAGG(referenced_name, ', ') WITHIN GROUP (ORDER BY referenced_name) AS dependencies
FROM user_dependencies
WHERE referencing_type IN ('PACKAGE', 'PROCEDURE', 'FUNCTION')
GROUP BY referencing_name, referencing_type
ORDER BY referencing_type, referencing_name;


-- ============================================
-- EXERCISE 6: Design your own backup strategy
-- ============================================
/* STEP 1: Document structure
*/
SELECT object_type, COUNT(*) FROM user_objects GROUP BY object_type;
SELECT table_name, num_rows FROM user_tables ORDER BY num_rows DESC;

/* STEP 2: Extract all DDL (Run these one by one and spool to files)
*/
-- (Transform params already set in Ex 3)
SELECT DBMS_METADATA.GET_DDL('TABLE', table_name) FROM user_tables;
SELECT DBMS_METADATA.GET_DDL('INDEX', index_name) FROM user_indexes;
SELECT DBMS_METADATA.GET_DDL('VIEW', view_name) FROM user_views;
SELECT DBMS_METADATA.GET_DDL('SEQUENCE', sequence_name) FROM user_sequences;
SELECT DBMS_METADATA.GET_DDL('CONSTRAINT', constraint_name) FROM user_constraints;
SELECT DBMS_METADATA.GET_DDL('PROCEDURE', object_name) FROM user_objects WHERE object_type = 'PROCEDURE';
SELECT DBMS_METADATA.GET_DDL('FUNCTION', object_name) FROM user_objects WHERE object_type = 'FUNCTION';
SELECT DBMS_METADATA.GET_DDL('PACKAGE', object_name) FROM user_objects WHERE object_type = 'PACKAGE';

/*
STEP 3: Reload Script Execution Order (Conceptual)
1. Execute Tables (no constraints)
2. Execute Sequences
3. Execute Indexes
4. Execute Constraints (Enables FKs)
5. Execute Views
6. Execute Procedures/Functions
*/

/*
STEP 4: Verify Post-Migration
*/
SELECT object_type, COUNT(*) FROM user_objects GROUP BY object_type;
SELECT table_name, num_rows FROM user_tables ORDER BY table_name;


-- ============================================
-- DISCUSSION QUESTIONS (Reference)
-- ============================================
/*
Q1: DBMS_METADATA vs expdp?
A: DBMS_METADATA is DDL only (no data), requires manual spooling, and is great when you lack DBA access. 
   expdp (Data Pump) is faster, exports data rows + DDL, handles huge schemas, but requires directory privileges.

Q2: Handling circular dependencies?
A: Create tables first, then enable constraints later. For PL/SQL, compile the PACKAGE SPEC first, 
   then compile the PACKAGE BODY.

Q3: Migration plan with read-only access?
A: 1. Document source. 2. Set EMIT_SCHEMA=false. 3. Extract DDL via DBMS_METADATA. 
   4. Clean DDL. 5. Create target schema. 6. Execute DDL in dependency order. 
   7. Verify object counts. 8. Export/Import data via CSV or INSERT statements if possible.
*/