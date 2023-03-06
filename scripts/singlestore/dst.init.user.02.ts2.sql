-- singlestore source and target has to match.  
-- if ts2 was added then remove
ALTER TABLE usertable DROP COLUMN ts2;
ALTER TABLE sbtest1 DROP COLUMN ts2;