CREATE USER myuser IDENTIFIED BY mypassword;
GRANT CONNECT TO myuser;
GRANT CREATE SESSION TO myuser;
GRANT CREATE TABLE TO myuser;
ALTER USER myuser QUOTA 100M ON users;
ALTER DATABASE default tablespace users;