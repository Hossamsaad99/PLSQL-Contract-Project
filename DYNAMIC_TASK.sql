/*

select * from user_triggers;
select * from user_dependencies;
select * from user_sequences;
select * from user_cons_columns;
select * from user_constraints;
select * from user_tab_columns;
*/


DECLARE
   EXISTING_OBJECT exception;
   PRAGMA EXCEPTION_INIT(EXISTING_OBJECT, -955);
   CURSOR TAB_CRS
                    IS
                    SELECT UCC.table_name, UCC.column_name
                    FROM user_constraints UC, user_cons_columns UCC, user_tab_columns UTC 
                    WHERE UCC.table_name = UC.table_name 
                               AND UCC.constraint_name = UC.constraint_name
                               AND UTC.table_name = UCC.table_name
                               AND UTC.column_name = UCC.column_name
                               AND UC.constraint_type = 'P' 
                               AND UTC.data_type = 'NUMBER'
                               AND UCC.table_name IN (SELECT table_name 
                                                                   FROM user_tables UT  
                                                                   WHERE table_name NOT IN (SELECT UT.table_name 
                                                                                                            FROM user_tables UT ,  user_triggers  TRIG ,user_dependencies  DEP , user_sequences  USEQ
                                                                                                            WHERE TRIG.table_name = UT.table_name 
                                                                                                                       AND  DEP.name = TRIG.trigger_name
                                                                                                                       AND USEQ.sequence_name = DEP.referenced_name));
BEGIN
   FOR TAB_REC IN TAB_CRS
   LOOP
   
      BEGIN
      
       EXECUTE IMMEDIATE   'CREATE SEQUENCE '||TAB_REC.table_name|| '_SEQ_TASK 
                                           START WITH 1 
                                           INCREMENT BY 1 
                                           MAXVALUE 99999999 
                                           MINVALUE 1
                                           NOCYCLE  CACHE 20   
                                           NOORDER';

         EXECUTE IMMEDIATE   'CREATE OR REPLACE TRIGGER '|| TAB_REC.table_name|| '_TRIG_TASK 
                                            BEFORE INSERT ON '|| TAB_REC.table_name||'
                                            REFERENCING NEW AS New OLD AS Old  
                                            FOR EACH ROW 
                                            BEGIN 
                                            :NEW.'||TAB_REC.column_name|| ' := '||TAB_REC.table_name||'_SEQ_TASK.NEXTVAL; 
                                            END;';
      EXCEPTION
                    WHEN EXISTING_OBJECT THEN
                    CONTINUE;
      END;
                   
   END LOOP;
END;

SHOW ERRORS;