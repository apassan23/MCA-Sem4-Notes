CREATE OR REPLACE FUNCTION somefunc() 
RETURNS integer AS 
$$ 
<< outerblock >>
DECLARE quantity integer := 30; 
BEGIN RAISE NOTICE 'Quantity here is %', quantity;
quantity := 50;
--
-- Create a subblock
--
DECLARE
    quantity integer := 80;
BEGIN
    RAISE NOTICE 'Quantity here is %', quantity;  -- Prints 80
    RAISE NOTICE 'Outer quantity here is %', outerblock.quantity;  -- Prints 50
END;

RAISE NOTICE 'Quantity here is %', quantity;  -- Prints 50

RETURN quantity;
END; $$ LANGUAGE plpgsql;

select someFunc();


do $$
declare
   actor_count integer; 
begin
   -- select the number of actors from the actor table
   select count(*)
   into actor_count
   from actor;

   -- show the number of actors
   raise notice 'The number of actors: %', actor_count;
end; $$ LANGUAGE plpgsql;

select * from actor;

do $$
declare
    actor_name record;
begin
    for actor_name in (select first_name, last_name
    from actor
    where actor_id < 10) loop
        raise notice 'Actor Name: % %', actor_name.first_name, actor_name.last_name;
    end loop;
end;$$


do $$ 
declare
   vat constant numeric := 0.1;
   net_price    numeric := 20.5;
begin
   raise notice 'The selling price is %', net_price * ( 1 + vat );
end $$;   



do $$ 
begin 
  raise info 'information message %', now() ;
  raise log 'log message %', now();
  raise debug 'debug message %', now();
  raise warning 'warning message %', now();
  raise notice 'notice message %', now();
end $$;

do $$
begin
    assert 1 = 2, 'LOL';
end;$$

CREATE OR REPLACE FUNCTION assert1(NUMERIC)
RETURNS NUMERIC
AS $$
BEGIN
ASSERT $1<20;
ASSERT $1>10,'Assert Message';
RETURN $1*2;
END;
$$ LANGUAGE plpgSQL;

do $$
declare val numeric := 0;
begin
    select assert1(15) into val;
    raise notice 'Val: %', val;
end;$$ 


set plpgsql.check_asserts = false;
select assert1(30);
set plpgsql.check_asserts = true;
select assert1(30);

select * from film;

create or replace function checkFilm(f_id int) returns int as
$$
declare 
    film_count integer := 0;
begin 
    select count(film_id)
    into film_count
    from film
    where film_id = f_id;
    
    if (film_count > 0) then 
        raise notice 'Film exists!';
    elsif (film_count != 0) then 
        raise notice 'LOL';
    else raise notice 'Film Does not exist';
    end if;
    
    return film_count;
end;$$ language plpgsql;

select checkFilm(100);

do $$
declare
  selected_film film%rowtype;
  input_film_id int := 1001;
begin  

  select * from film
  into selected_film
  where film_id = input_film_id;
  
  -- found is a global variable
  -- if the select into statement succeeds then true
  -- otherwise false
  if not found then
     raise notice'The film % could not be found', 
	    input_film_id;
  end if;
end $$ 

-- Simple LOOP
do $$
declare
   n integer:= 10;
   fib integer := 0;
   counter integer := 0 ; 
   i integer := 0 ; 
   j integer := 1 ;
   tmp integer;
begin
	if (n < 1) then
		fib := 0 ;
	end if; 
	loop 
		exit when counter = n ; 
		counter := counter + 1 ; 
		tmp := j;
        j := i + j;
        i := tmp;
	end loop; 
	fib := i;
    raise notice '%', fib; 
end; $$


-- WHILE LOOP
do $$
declare
   n integer:= 10;
   fib integer := 0;
   counter integer := 0 ; 
   i integer := 0 ; 
   j integer := 1 ;
   tmp integer;
begin
	if (n < 1) then
		fib := 0 ;
	end if; 
	while counter != n loop
        tmp := j;
        j := i + j;
        i := tmp;
        counter := counter + 1;
    end loop;
	fib := i;
    raise notice '%', fib; 
end; $$


-- FOR LOOP
do $$
declare
   n integer:= 10;
   fib integer := 0;
   counter integer;
   i integer := 0 ; 
   j integer := 1 ;
   tmp integer;
begin
	if (n < 1) then
		fib := 0 ;
	end if; 
	for counter in 1..10 loop
        tmp := j;
        j := i + j;
        i := tmp;
    end loop;
	fib := i;
    raise notice '%', fib; 
end; $$

do $$
declare 
    counter integer := 0;
begin
    for counter in 1..5 loop
        if (counter = 2) then
            continue;
        else 
            raise notice 'Counter: %', counter;
        end if;            
    end loop;
end; $$

select * from film;

create or replace function countBetween(len_from int, len_to int) 
returns int as 
$$
declare
    film_count int := 0;
begin
    select count(film_id)
    into film_count
    from film
    where length between len_from and len_to;

return film_count;
end;$$ language plpgsql;

select countBetween(len_to => 90, len_from => 40);

create or replace function get_film_stat(
    out min_len int,
    out max_len int,
    out avg_len numeric) 
language plpgsql
as 
$$
begin
  
  select min(length),
         max(length),
		 avg(length)::numeric(5,1)
  into min_len, max_len, avg_len
  from film;

end;
$$

select * from get_film_stat();

create or replace function swap(
	inout x int,
	inout y int
) 
language plpgsql	
as $$
begin
   select x,y into y,x;
end; $$;

select * from swap(10, 20);

CREATE OR REPLACE FUNCTION get_rental_duration(p_customer_id INTEGER, p_from_date DATE)
    RETURNS INTEGER AS $$
DECLARE 
    rental_duration integer;
BEGIN
    -- get the rental duration based on customer_id and rental date
    SELECT SUM( EXTRACT( DAY FROM return_date - rental_date))  INTO rental_duration                
    FROM rental 
    WHERE customer_id= p_customer_id AND 
          rental_date >= p_from_date;
     
    RETURN rental_duration;
END; $$
LANGUAGE plpgsql;


select * from film;

create or replace function get_film (
  p_pattern varchar
) 
	returns table (
		film_title varchar,
		film_release_year int
	) 
	language plpgsql
as $$
begin
	return query 
		(select title, release_year::integer
		from film
		where title ilike p_pattern);
end;
$$

select * from get_film('Am%');

drop function if exists get_rental_duration cascade;

-- Same as functions but we can use transactions in this
-- cannot have out mode
-- can use commit
-- no need to use begin because it is already there LOL!
-- Calling: call procedure_name(args);
create or replace procedure transfer(
   sender int,
   receiver int, 
   amount dec
)
language plpgsql    
as $$
begin
    -- subtracting the amount from the sender's account 
    update accounts 
    set balance = balance - amount 
    where id = sender;

    -- adding the amount to the receiver's account
    update accounts 
    set balance = balance + amount 
    where id = receiver;

    commit;
end;$$

call transfer(1,2,1000);


-- Triggers
-- Advantages:
-- 1. Ability to enforce referential integrity
-- 2. Ability of monitoring
-- 3. Ability to stop transactions that are not valid
-- 4. Ability to enforce security measures
-- 5. Ability to produce derived column values by default

-- Types:
-- 1. Row-level (FOR EACH ROW clause)
-- 2. Statement-level (FOR EACH STATEMENT clause)
-- difference between them is how many times they are invoked and at what time
-- Row-level is fired for each row
-- Statement level is fired for each transaction

-- 1. BEFORE trigger: The trigger is fired before the change is made to the table.
-- 2. AFTER trigger: The trigger is fired after the change is made to the table.

CREATE TABLE employee_info(
   id INT GENERATED ALWAYS AS IDENTITY,
   first_name VARCHAR(40) NOT NULL,
   last_name VARCHAR(40) NOT NULL,
   PRIMARY KEY(id)
);


CREATE TABLE employee_audits (
   id INT GENERATED ALWAYS AS IDENTITY,
   employee_id INT NOT NULL,
   last_name VARCHAR(40) NOT NULL,
   changed_on TIMESTAMP(6) NOT NULL
);

-- Create trigger function
-- The OLD represents the row before update while the NEW represents the new row that will be updated. 
-- The OLD.last_name returns the last name before the update and the NEW.last_name returns the new last name


-- Syntax:
-- create trigger trigger_name 
-- ( AFTER | BEFORE ) event 
-- ON table_name 
-- FOR EACH ( ROW | STATEMENT ) 
-- EXECUTE PROCEDURE function_name();

CREATE OR REPLACE FUNCTION log_last_name_changes()
  RETURNS TRIGGER 
  LANGUAGE PLPGSQL
  AS
$$
BEGIN
	IF NEW.last_name <> OLD.last_name THEN
		 INSERT INTO employee_audits(employee_id,last_name,changed_on)
		 VALUES(OLD.id,OLD.last_name,now());
	END IF;

	RETURN NEW;
END;
$$
-- Bind the trigger

CREATE TRIGGER last_name_changes
  BEFORE UPDATE
  ON employee_info
  FOR EACH ROW
  EXECUTE PROCEDURE log_last_name_changes();

drop trigger last_name_changes on employee_info;

insert into employee_info(first_name, last_name)
values ('ABC', 'XYZ');

update employee_info
set first_name = 'ABC', last_name = 'PQR'
where id = 1;

select * from employee_audits;

-- ALTER TRIGGER trigger_name 
-- ON table_name
-- RENAME TO new_name;

-- ALTER TABLE table_name DISABLE TRIGGER ( trigger_name | ALL );

