/****************** INSTALLMENTS_PAID TABLE***********************/


-- TABLE CREATION

CREATE TABLE INSTALLMENTS_PAID
(
   Installment_ID        NUMBER (5) CONSTRAINT ISNT_ID_PK PRIMARY KEY,
   Contract_ID      NUMBER (5) CONSTRAINT Cont_ID_FK REFERENCES Contracts(Contract_ID),
   Installment_Date   date CONSTRAINT ISNT_DATE_NN NOT NULL,
   Installment_Amount    number(15,4),
   Paid number(2)  DEFAULT 0
);

-- CREATE INSTALLMENT ID SEQUENCE

CREATE SEQUENCE INSTALLMENT_ID_SEQ
   START WITH 1
   INCREMENT BY 1
   MAXVALUE 10000
   MINVALUE 1
   NOCYCLE
   NOORDER;

-- CREATE TRIGGER ON INSTALLMENT IDSEQUENCE ON INSTALLMENTS_PAID TABLE

CREATE OR REPLACE TRIGGER INSTALLMENT_ID_TRG
   BEFORE INSERT
   ON HR.INSTALLMENTS_PAID
   REFERENCING NEW AS New OLD AS Old
   FOR EACH ROW
BEGIN
   :NEW.Installment_ID := INSTALLMENT_ID_SEQ.NEXTVAL;
END INSTALLMENT_ID_TRG;



-- CREATE PROCEDURES TO INSERT VALUES BASED ON CONTRACTS ROWS

CREATE OR REPLACE PROCEDURE UPDATE_INSTALLMENTS

AS
    CONTID number(4);
    ISNTDATE DATE;
    UNPAMT number(15,4);
    CONT_TYPE varchar2(50);
    PAY_INST_NO number(4);
    MNID number(4);
    MXID number(4);
    INST_AMT NUMBER(20,6);
    
BEGIN

    SELECT MIN(Contract_ID), Max(Contract_ID)
    INTO MNID, MXID
    FROM Contracts;
    
    FOR CID IN MNID..MXID
    LOOP
    
        SELECT Contract_ID, CLIENT_STARTDATE, CONTRACT_TOT_PAY(Contract_ID), PAYMENTS_INSTALLMENTS_NO, CONTRACT_PAYMENT_TYPE
        
        INTO    CONTID, ISNTDATE, UNPAMT, PAY_INST_NO, CONT_TYPE
        FROM Contracts
        WHERE Contract_ID = CID;
             
        FOR PN in 1..PAY_INST_NO
        LOOP
        
            IF PN = 1 THEN
                ISNTDATE := ISNTDATE;
                
            ELSE
            
                SELECT MAX(ISNTDATE) INTO ISNTDATE FROM INSTALLMENTS_PAID WHERE Contract_ID = CID;
               
                IF CONT_TYPE = 'ANNUAL' THEN
                    ISNTDATE := ADD_MONTHS(ISNTDATE, 12);
                    
                ELSIF CONT_TYPE = 'HALF_ANNUAL' THEN
                    ISNTDATE := ADD_MONTHS(ISNTDATE, 6);
                    
                ELSIF CONT_TYPE = 'QUARTER' THEN
                    ISNTDATE := ADD_MONTHS(ISNTDATE, 3);
                    
                ELSE
                    ISNTDATE := ADD_MONTHS(ISNTDATE, 1);
                END IF;
                
           END IF;
           
           INST_AMT := UNPAMT / PAY_INST_NO;
           
            INSERT INTO INSTALLMENTS_PAID(CONTRACT_ID, INSTALLMENT_DATE, INSTALLMENT_AMOUNT)
            VALUES(CONTID,ISNTDATE, INST_AMT);
            
        END LOOP;
        
  END LOOP;
  
END;


SHOW ERRORS;

