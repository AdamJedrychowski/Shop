DROP SCHEMA shop CASCADE;
CREATE SCHEMA shop;

DROP TYPE GENDER_TYPE CASCADE;
CREATE TYPE GENDER_TYPE AS ENUM ('Brak', 'Mężczyzna', 'Kobieta', 'Inny');

CREATE TABLE shop.Gender (
    id SERIAL,
    gender GENDER_TYPE,
    CONSTRAINT gender_pk PRIMARY KEY (id)
);


CREATE TABLE shop.Nationality (
    id SERIAL,
    country VARCHAR(50) NOT NULL UNIQUE,
    CONSTRAINT nationality_pk PRIMARY KEY (id)
);


CREATE TABLE shop.Client (
    id SERIAL,
    name VARCHAR(20) NOT NULL,
    surname VARCHAR(30) NOT NULL,
    email VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(40) NOT NULL,
    age INTEGER NOT NULL,
    id_gender INTEGER NOT NULL,
    id_country INTEGER NOT NULL,
    CONSTRAINT client_pk PRIMARY KEY (id),
    CONSTRAINT gender_fk FOREIGN KEY (id_gender)
        REFERENCES shop.Gender(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
        NOT DEFERRABLE,
    CONSTRAINT nationality_fk FOREIGN KEY (id_country)
        REFERENCES shop.Nationality(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
        NOT DEFERRABLE
);


CREATE TABLE shop.Job (
    id SERIAL,
    role VARCHAR(15) NOT NULL UNIQUE,
    CONSTRAINT job_pk PRIMARY KEY (id)
);


CREATE TABLE shop.Employee (
    id SERIAL,
    name VARCHAR(20) NOT NULL,
    surname VARCHAR(30) NOT NULL,
    email VARCHAR(40) NOT NULL UNIQUE,
    password VARCHAR(40) NOT NULL,
    id_role INTEGER NOT NULL,
    CONSTRAINT employee_pk PRIMARY KEY (id),
    CONSTRAINT role_fk FOREIGN KEY (id_role)
        REFERENCES shop.Job(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
        NOT DEFERRABLE
);


CREATE TABLE shop.Order (
    id SERIAL,
    location VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    date DATE NOT NULL,
    id_client INTEGER NOT NULL,
    id_employee INTEGER,
    CONSTRAINT order_pk PRIMARY KEY (id),
    CONSTRAINT client_fk FOREIGN KEY (id_client)
        REFERENCES shop.Client(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
        NOT DEFERRABLE,
    CONSTRAINT employee_fk FOREIGN KEY (id_employee)
        REFERENCES shop.Employee(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
        NOT DEFERRABLE
);


CREATE TABLE shop.Item (
    id SERIAL,
    name VARCHAR(20) NOT NULL UNIQUE,
    price INTEGER NOT NULL,
    number INTEGER NOT NULL,
    CONSTRAINT item_pk PRIMARY KEY (id)
);


CREATE TABLE shop.Order_item (
    id_order INTEGER NOT NULL,
    id_item INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    CONSTRAINT order_item_pk PRIMARY KEY (id_order, id_item),
    CONSTRAINT order_fk FOREIGN KEY (id_order)
        REFERENCES shop.Order(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
        NOT DEFERRABLE,
    CONSTRAINT item_fk FOREIGN KEY (id_item)
        REFERENCES shop.Item(id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION
        NOT DEFERRABLE
);