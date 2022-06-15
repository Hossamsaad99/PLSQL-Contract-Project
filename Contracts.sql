/****************** CONTRACTS TABLE ***********************/

--- CREATE TABLE DESIGN

CREATE TABLE Contracts
(
   Contract_ID        NUMBER (5) CONSTRAINT Cont_ID_PK PRIMARY KEY,
   Client_Startdate      date CONSTRAINT Cont_STD_NN NOT NULL,
   Client_Enddate   date  CONSTRAINT Cont_END_NN NOT NULL,
   Payments_Installments_No number(15,4) DEFAULT 0,
   Contract_Total_Fees number(15,4),
   Contract_Deposit_Fees number(15,4),
   Client_ID NUMBER (5) CONSTRAINT CL_ID_FK REFERENCES Clients(Client_ID),
   Contract_Payment_Type Varchar2(20) CONSTRAINT Cont_Pay_NN NOT NULL,
   Notes varchar2(50)
);


-- CREATE CONTRACT ID SEQUENCE

CREATE SEQUENCE CONTRACT_ID_SEQ
   START WITH 1
   INCREMENT BY 1
   MAXVALUE 10000
   MINVALUE 1
   NOCYCLE
   NOORDER;

-- CREATE TRIGGER ON CONTRACTS ID SEQUENCE ON CONTRACTS TABLE

CREATE OR REPLACE TRIGGER CONTRACT_ID_TRG
   BEFORE INSERT
   ON HR.Contracts
   REFERENCING NEW AS New OLD AS Old
   FOR EACH ROW
BEGIN
   :NEW.Contract_ID := CONTRACT_ID_SEQ.NEXTVAL;
END CONTRACT_ID_TRG;


--- CREATE CONTRACTS INSERTION  PROCEDURE 

CREATE OR REPLACE PROCEDURE CONTRACTS_INSERTION (CNT_STD DATE,
                                                 CNT_END DATE,
                                                 CNT_TOT_FEE   NUMBER,
                                                 CNT_DEPS_FEE   NUMBER,
                                                 CLNT_ID  NUMBER,
                                                 CNT_PAY_TYP  VARCHAR2)
AS
RR Number (4);
CNT_ID number(4);
BEGIN
   
   INSERT INTO Contracts (CLIENT_STARTDATE,
                          CLIENT_ENDDATE,
                          CONTRACT_TOTAL_FEES,
                          CONTRACT_DEPOSIT_FEES,
                          CLIENT_ID,
                          CONTRACT_PAYMENT_TYPE)
        VALUES (CNT_STD,
                 CNT_END, 
                CNT_TOT_FEE,
                CNT_DEPS_FEE,
                CLNT_ID,
                CNT_PAY_TYP);
    
END;
/********************************************/

-- CREATE TRIGGER FOR UPDATING PAY_NO CLOUMN  BASED ON CONTRACT PAYMENT TYPE

CREATE OR REPLACE TRIGGER PAY_NO_TRG
   BEFORE INSERT OR UPDATE
   ON HR.Contracts
   REFERENCING NEW AS New OLD AS Old
   FOR EACH ROW
DECLARE
   Months   NUMBER(4) ;
BEGIN

   Months := MONTHS_BETWEEN (:NEW.CLIENT_ENDDATE , :NEW.CLIENT_STARTDATE);

   IF :NEW.Contract_Payment_Type = 'ANNUAL'
   THEN
      :NEW.PAYMENTS_INSTALLMENTS_NO := Months / 12;
   ELSIF :NEW.Contract_Payment_Type = 'QUARTER'
   THEN
      :NEW.PAYMENTS_INSTALLMENTS_NO := Months / 3;
   ELSIF :NEW.Contract_Payment_Type = 'MONTHLY'
   THEN
      :NEW.PAYMENTS_INSTALLMENTS_NO := Months / 1;
   ELSIF :NEW.Contract_Payment_Type = 'HALF_ANNUAL'
   THEN
      :NEW.PAYMENTS_INSTALLMENTS_NO := Months / 6;
   END IF;
END;

SHOW ERRORS;

-- CREATE FUNCTION TO CALCULATE REMAINING PAYMENT TOTAL FOR EACH CONTRACT ID 

CREATE OR REPLACE FUNCTION CONTRACT_TOT_PAY (ContID in NUMBER)
   RETURN NUMBER
IS
   VCONTS Contracts%ROWTYPE;
   Remain_Total   NUMBER;
   PAY_NO number;
   PAY_Parts number;
BEGIN
   SELECT *
     INTO VCONTS
     FROM Contracts
    WHERE Contract_ID = ContID;

   Remain_Total := VCONTS.CONTRACT_TOTAL_FEES - NVL(VCONTS.CONTRACT_DEPOSIT_FEES,0);
   RETURN Remain_Total;
END;

