CREATE DATABASE WAVE;


--CREATE TABLE USERS
CREATE TABLE users (
u_id integer PRIMARY KEY,
name text NOT NULL,
mobile text NOT NULL,
wallet_id integer NOT NULL,
when_created timestamp without time zone NOT NULL);

--Create transfers table
CREATE TABLE transfers (
transfer_id integer PRIMARY KEY,
u_id integer NOT NULL,
source_wallet_id integer NOT NULL,
dest_wallet_id integer NOT NULL,
send_amount_currency text NOT NULL,
send_amount_scalar numeric NOT NULL,
receive_amount_currency text NOT NULL,
receive_amount_scalar numeric NOT NULL,
kind text NOT NULL,
dest_mobile text,
dest_merchant_id integer,
when_created timestamp without time zone NOT NULL);

--Alter table transfer
ALTER TABLE public.transfers
    ADD FOREIGN KEY (source_wallet_id)
    REFERENCES public.wallets (wallet_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;

-- CREATE agents Table
CREATE TABLE agents (
agent_id integer PRIMARY KEY,
name text,
country text NOT NULL,
region text,
city text,
subcity text,
when_created timestamp without time zone NOT NULL);

--Create table Agent transactions
CREATE TABLE agent_transactions (
atx_id integer PRIMARY KEY,
u_id integer NOT NULL,
agent_id integer NOT NULL,
amount numeric NOT NULL,
fee_amount_scalar numeric NOT NULL,
when_created timestamp without time zone NOT NULL);

--Alter table agent_transactions
ALTER TABLE public.agent_transactions
    ADD FOREIGN KEY (agent_id)
    REFERENCES public.agents (agent_id) MATCH SIMPLE
    ON UPDATE CASCADE
    ON DELETE CASCADE;

--Create Wallets Table
CREATE TABLE wallets (
wallet_id integer PRIMARY KEY,
currency text NOT NULL,
ledger_location text NOT NULL,
when_created timestamp without time zone NOT NULL);

--Question 1
SELECT COUNT(u_id)
FROM users;
-- this gives the total number of users 

--Question 2
SELECT COUNT(*)
FROM transfers
WHERE send_amount_currency = 'CFA';
-- this gives the number of transfers in CFA. 

--QUESTION 3
SELECT COUNT (DISTINCT u_id) 
FROM transfers
WHERE send_amount_currency = 'CFA';
-- this gives the number of transactions made by users in CFA

--Question 4
SELECT COUNT (atx_id)
FROM agent_transactions
WHERE EXTRACT(MONTH FROM when_created) = 2018;
-- this gives the number of transactions broken down by each month for 2018

--Question 5
WITH agent_withdrawers AS
(SELECT COUNT (agent_id)
AS net_withdrawers
FROM agent_transactions 
HAVING COUNT (amount)
IN (SELECT COUNT (amount) FROM agent_transactions WHERE amount > -1 
AND amount !=0 HAVING COUNT (amount) > (SELECT COUNT(amount)
FROM agent_transactions WHERE amount < 1 AND  AMOUNT !=0)))
SELECT net_withdrawers
FROM agent_withdrawers;
-- shows number of net depositors 


--Question 6
CREATE TABLE atx_volume_city_summary AS
SELECT array_agg(agent_transactions.atx_id), agents.city 
FROM agent_transactions
LEFT OUTER JOIN agents ON agent_transactions.agent_id = agents.agent_id
WHERE agent_transactions.when_created > CURRENT_DATE - INTERVAL '7 days'
GROUP BY agents.city;
--agent transaction summary by city



--Question 7
CREATE TABLE atx_volume_city_country_summary AS
SELECT COUNT(agent_transactions.atx_id), agents.city, agents.country
FROM agent_transactions
LEFT OUTER JOIN agents ON agent_transactions.agent_id = agents.agent_id
WHERE agent_transactions.when_created > CURRENT_DATE - INTERVAL '7 days'
GROUP BY agents.city, agents.country;
--agent transaction summary by country


--Question 8
CREATE TABLE send_volume_by_country_and_kind AS
SELECT SUM(transfers.send_amount_scalar), wallets.ledger_location, array_agg(transfers.kind) 
FROM transfers
LEFT OUTER JOIN wallets ON transfers.source_wallet_id = wallets.wallet_id
WHERE transfers.when_created > CURRENT_DATE - INTERVAL '7 days'
GROUP BY wallets.ledger_location;
--send volume by sum 


--Question 9
CREATE TABLE transaction_by_country_and_kind AS
SELECT COUNT (transfers.transfer_id), wallets.ledger_location, array_agg(transfers.kind) 
FROM transfers
LEFT OUTER JOIN wallets ON transfers.source_wallet_id = wallets.wallet_id
WHERE transfers.when_created > CURRENT_DATE - INTERVAL '7 days'
GROUP BY wallets.ledger_location;
--Send volume by count


--Question 10
SELECT users.u_id, transfers.send_amount_scalar, transfers.when_created
FROM transfers
INNER JOIN USERS
ON transfers.u_id = users.u_id
WHERE send_amount_currency = 'CFA'
AND send_amount_scalar > 10000000
AND transfers.when_created > CURRENT_DATE - INTERVAL '1 Month'
-- transactions exceeding 10,000,000 CFA