######################## User 1: amit1

CREATE USER amit1 IDENTIFIED BY amit1;

GRANT dba TO amit1;

DROP TABLE amit1.tab_cols_withspace;

DROP TABLE amit1.sales;

DROP TABLE amit1.item_detail;

DROP TABLE amit1.item;

CREATE TABLE amit1.tab_cols_withspace (
    col1               NUMBER,
    col2 withspace   VARCHAR2(100),
    col3 withspace   NUMBER
);

INSERT INTO amit1.tab_cols_withspace VALUES (
    1,
    'amit',
    11
);

INSERT INTO amit1.tab_cols_withspace VALUES (
    2,
    'avyaan',
    22
);

COMMIT;

SELECT
    *
FROM
    amit1.tab_cols_withspace;

CREATE OR REPLACE VIEW amit1.view_cols_withspace (
    v_col1,
    v_col2 withspace,
    v_col3 withspace
) AS
    SELECT
        *
    FROM
        amit1.tab_cols_withspace;

CREATE TABLE amit1.item (
    srno           NUMBER,
    name           VARCHAR2(100),
    rating         NUMBER(10, 2),
    qty_in_stock   NUMBER(8),
    CONSTRAINT ITEM_PK PRIMARY KEY ( SRNO )
);

INSERT INTO amit1.item VALUES (
    1,
    'Cup',
    5,
    1000
);

INSERT INTO amit1.item VALUES (
    2,
    'Bottle',
    2,
    5000
);

INSERT INTO amit1.item VALUES (
    3,
    'Notepad',
    4,
    800
);

SELECT
    *
FROM
    amit1.item;

CREATE TABLE amit1.item_detail (
    srno          NUMBER,
    detail        VARCHAR2(30),
    description   VARCHAR2(50)
);

INSERT INTO amit1.item_detail VALUES (
    1,
    'colour',
    'blue'
);

INSERT INTO amit1.item_detail VALUES (
    2,
    'colour',
    'red'
);

INSERT INTO amit1.item_detail VALUES (
    1,
    'size',
    'h10w20d30'
);

INSERT INTO amit1.item_detail VALUES (
    2,
    'size',
    'h15w25d35'
);

CREATE TABLE AMIT1.sales (
    SRNO        NUMBER
        NOT NULL ENABLE,
    ITEM_SRNO   NUMBER,
    QUANTITY    NUMBER,
    DATE_SOLD   DATE,
    CONSTRAINT SALES_PK PRIMARY KEY ( SRNO ),
    CONSTRAINT SALES_FK1 FOREIGN KEY ( SRNO )
        REFERENCES AMIT1.ITEM ( SRNO )
    ENABLE
)
SEGMENT CREATION DEFERRED
PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING TABLESPACE USERS;


################ Trigger

CREATE OR REPLACE TRIGGER amit1.upd_item_stock AFTER
    INSERT ON amit1.sales
    FOR EACH ROW
BEGIN
    UPDATE item
    SET
        qty_in_stock = qty_in_stock - :new.quantity
    WHERE
        srno = :new.ITEM_SRNO;

END;
/

INSERT INTO amit1.sales VALUES (
    1,
    1,
    100,
    sysdate
);

INSERT INTO amit1.sales VALUES (
    2,
    1,
    100,
    sysdate
);

INSERT INTO amit1.sales VALUES (
    3,
    3,
    50,
    sysdate
);

SELECT
    *
FROM
    amit1.item;

COMMIT;

################ Package

CREATE OR REPLACE PACKAGE pack1 IS
    PROCEDURE get_date;

    FUNCTION get_rand_no RETURN NUMBER;

END pack1;
/

CREATE OR REPLACE PACKAGE BODY pack1 IS

    PROCEDURE get_date IS
    BEGIN
        dbms_output.put_line('Date is: ' || to_char(sysdate, 'DD-MON-YYYY HH24:MI:SS'));
    END get_date;

    FUNCTION get_rand_no RETURN NUMBER IS
        l_numberplus1 NUMBER;
    BEGIN
        SELECT
            1 + 1
        INTO l_numberplus1
        FROM
            dual;

        RETURN l_numberplus1;
    END get_rand_no;

END pack1;
/





########################### USER 2 : amit2


CREATE USER amit2 IDENTIFIED BY amit2;

GRANT dba TO amit2;

drop table amit2.item; 

INSERT INTO amit1.item VALUES (
    4,
    'Saucer',
    5,
    10000
);

INSERT INTO amit1.item VALUES (
    5,
    'Opener',
    2,
    50000
);

INSERT INTO amit1.item VALUES (
    6,
    'Pencil',
    4,
    8000
);

select * from amit1.item;


drop table amit2.sales; 

grant REFERENCES, Insert, select, update on amit1.item to amit2;

CREATE TABLE amit2.sales (
    SRNO        NUMBER NOT NULL ENABLE,
    ITEM_SRNO   NUMBER,
    QUANTITY    NUMBER,
    DATE_SOLD   DATE,
    CONSTRAINT SALES_PK PRIMARY KEY ( SRNO ),
    CONSTRAINT SALES_FK1 FOREIGN KEY ( SRNO )
        REFERENCES amit1.ITEM ( SRNO )
    ENABLE
) ;




CREATE OR REPLACE TRIGGER amit2.upd_item_stock AFTER
    INSERT ON amit2.sales
    FOR EACH ROW
BEGIN
    UPDATE amit1.item
    SET
        qty_in_stock = qty_in_stock - :new.quantity
    WHERE
        srno = :new.ITEM_SRNO;
END;
/

select * from amit1.sales;
select * from amit2.sales;
select * from amit1.item;


INSERT INTO amit2.sales VALUES (
    4,
    4,
    1000,
    sysdate
);
