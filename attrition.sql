-- Querying attrition rate against various factors

-- avg attrtion rate for all departments

select round(avg(ct),2) "avg attrition rate" from (
select Department, sum(EmployeeCount)*100/tot_ct ct from(
select Department,EmployeeCount,Attrition, sum(EmployeeCount) over(partition by Department) tot_ct
from hr) as T1
where Attrition like "Yes"
group by Department, tot_ct) as T2;




-- attrition rate vs monthly income stats


select count(*)*100/ct attrition_rate, income_levels from 
(select EmployeeNumber, Attrition from hr) as h1 join (
select *, count(*) over(partition by income_levels) ct from (
select `Employee ID` as EID,
case
when MonthlyIncome <=10000 then "Level 1: <=10k"
when MonthlyIncome <=20000 then "Level 2: <=20k"
when MonthlyIncome <=30000 then "Level 3: <=30k"
when MonthlyIncome <=40000 then "Level 4: <=40k"
when MonthlyIncome <=50000 then "Level 5: <=50k"
else "Level 6: <=60k"
end income_levels
from hr_2) as T1) as h2 on h1.EmployeeNumber=h2.EID 
where Attrition like "Yes"
group by income_levels, ct;

-- attrition rate vs performance rating

select PerformanceRating, count(*)*100/ct as attrition_rate  from (
(select EmployeeNumber, Attrition from hr) as h1 join 
(select `Employee ID`, PerformanceRating, count(*) over (partition by PerformanceRating) as ct from hr_2) as h2 
on h1.EmployeeNumber=h2.`Employee ID`)
where Attrition like "yes"
group by PerformanceRating,ct;

-- attrition rate vs education
select Education, count(*)*100/ct as attrition_rate  from (
(select Education, Attrition, count(*) over (partition by Education) ct from hr)) as T1
where Attrition like "yes"
group by Education,ct;

-- attrition rate vs year since last promotion

with att_rate as(
select * from (
(select EmployeeNumber,
case
when Attrition like "Yes" then 1
else 0
end attrition
 from hr) as T1
join 
(select `Employee ID`,YearsSinceLastPromotion from hr_2) T2 on EmployeeNumber=`Employee ID`))
select YearsSinceLastPromotion, sum(Attrition)*100/tot_ct attrition_rate
from (
select *, count(EmployeeNumber) over (partition by YearsSinceLastPromotion) tot_ct from att_rate
) as T1
group by YearsSinceLastPromotion, tot_ct;

-- attrition rate vs job role

select JobRole, count(*)*100/ct as attrition_rate  from (
(select JobRole, Attrition, count(*) over (partition by JobRole) ct from hr)) as T1
where Attrition like "yes"
group by JobRole,ct;

-- attrition rate vs gender and marital status

select Gender,MaritalStatus, count(*)*100/ct as attrition_rate  from (
(select Gender, MaritalStatus,Attrition, count(*) over (partition by Gender,MaritalStatus) ct from hr)) as T1
where Attrition like "yes"
group by Gender, MaritalStatus, ct;


-- few other indicators

-- median percentsalaryhike

with base as (
select PercentSalaryHike, row_number() over(partition by order by PercentSalaryHike) rn
    from hr_2
),
ct as (
select count(rn) from base
),
odd as (
		select PercentSalaryHike
        from base
        where rn=((select * from ct)+1)/2
), 
even as (
	select 
		((select PercentSalaryHike
			from base
            where rn=((select * from ct))/2)+(
			select PercentSalaryHike
            from base
            where rn=((select * from ct)/2)+1
            ))/2
)
select 
case 
    when count(PercentSalaryHike)%2=0 then (select * from even)
    else (select * from odd)
    end `median PercentSalaryHike`
from base;




-- avg working years for each department

select Department, avg(YearsAtCompany) "working years"
from hr join hr_2 on EmployeeNumber=`Employee ID`
group by Department;

-- job role vs work life balance

With ratings as 
(select JobRole, WorkLifeBalance, EmployeeNumber
from hr join hr_2 on EmployeeNumber=`Employee ID`)
select r1.JobRole, `rate:1`,`rate:2`,`rate:3`,`rate:4`
from 
(select JobRole, count(EmployeeNumber) "rate:1" from ratings where WorkLifeBalance=1 group by JobRole) as r1 
join 
(select JobRole, count(EmployeeNumber) "rate:2" from ratings where WorkLifeBalance=2 group by JobRole) as r2
join
(select JobRole, count(EmployeeNumber) "rate:3" from ratings where WorkLifeBalance=3 group by JobRole) as r3
join
(select JobRole, count(EmployeeNumber) "rate:4" from ratings where WorkLifeBalance=4 group by JobRole) as r4
on r1.JobRole=r2.JobRole and r2.JobRole=r3.JobRole and r3.JobRole=r4.JobRole;






-- avg hourly rate of male research scientists

select avg(HourlyRate)
from hr
where Gender like "Male" and JobRole like "Research Scientist";







