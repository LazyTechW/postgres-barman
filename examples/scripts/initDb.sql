CREATE DATABASE sales OWNER postgres;

\c sales;

CREATE TABLE IF NOT EXISTS films (
    code        char(5) CONSTRAINT firstkey PRIMARY KEY,
    title       varchar(40) NOT NULL,
    did         integer NOT NULL,
    date_prod   date,
    kind        varchar(10),
    len         interval hour to minute
);

INSERT INTO films VALUES
    ('UA502', 'Bananas', 105, '1971-07-13', 'Comedy', '82 minutes');

INSERT INTO films VALUES
    ('UA503', 'Apple', 105, '1971-07-13', 'Comedy', '82 minutes');
ALTER TABLE films 
  ADD COLUMN mtime timestamp with time zone DEFAULT now();
