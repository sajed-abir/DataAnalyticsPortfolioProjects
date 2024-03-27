/*
Covid 19 dataset analysis
Skills: Data retrieval, aggregation, grouping, filtering, 
		sorting, window function, CTE, Temp table, view creation, error handling
*/
--Global numbers: Total cases, total deaths, death percentage
select
sum(new_cases) as total_cases,
sum(cast(new_deaths as int)) as total_deaths,
sum(cast(new_deaths as int)) / sum(new_cases) * 100 as death_percentage
from PortfolioProject..covid_deaths
where continent is not null
order by 1,2


--contintents with the highest death and infection count per population
select
continent,
max(cast(total_deaths as int)) as total_death_count,
max(cast(total_cases as int)) as total_case_count
from PortfolioProject..covid_deaths
where continent is not null
group by continent
ORDER BY total_death_count desc


--Total infected and deaths by country
select 
location as country, 
sum(new_cases) as total_infected_per_country,
sum(new_deaths) as total_deaths_per_country
from PortfolioProject..covid_deaths
where continent is not null
group by location
order by total_deaths_per_country desc


--Highest to lowest death rates
select
location as country,
sum(new_deaths) as total_deaths_per_country,
case
	when 
		sum(case when isnumeric(total_cases) = 1 then try_cast(total_cases as decimal) else 0 end) <> 0
		then (sum(new_deaths) * 100) / sum(case when isnumeric(total_cases) = 1 
		then try_cast(total_cases as decimal) else 0 end)
	else 0
end as death_rate
from PortfolioProject..covid_deaths
--where location = 'Bangladesh'
where continent is not null --and location like '%states%'
group by location
order by death_rate desc


--Average daily deaths globally and per country
select
'World' as location,
avg(new_deaths) as average_daily_deaths
from PortfolioProject..covid_deaths

--union all

select
location as country,
avg(new_deaths) as average_daily_deaths
from PortfolioProject..covid_deaths
where location is not null
	and continent is not null
group by location
order by average_daily_deaths desc


--Total cases vs total deaths
select 
location,
date,
total_cases, 
total_deaths, 
case
	when try_cast(total_cases as decimal(18,2)) <> 0 
	then try_cast(total_deaths as decimal(18,2)) / try_cast(total_cases as decimal(18,2)) * 100
end as death_rate_percentage
from PortfolioProject..covid_deaths
--where location = 'Bangladesh' and 
where TRY_CAST(total_cases AS DECIMAL(18,2)) <> 0 
order by 1,2


--Total cases vs population
select 
location,
date,
total_cases,
population,
(total_cases / population) * 100 as total_case_percentage
from PortfolioProject..covid_deaths
where
total_cases is not null and
population is not null
ORDER BY 1,2
--Location, Date;


--Total population vs vaccination
-- using subquery
select
continent,
location,
date,
population,
new_vaccinations,
sum(cast(new_vaccinations as bigint)) over 
	(partition by location order by date) 
		as rolling_new_vaccinations			--Rolling count of total people vaccinated

from
(
select distinct
death.continent,
death.location,
death.date,
min(death.population) as population,
min(vaccine.new_vaccinations) as new_vaccinations

from PortfolioProject..covid_deaths as death
join PortfolioProject..covid_vaccination as vaccine
on death.location = vaccine.location
and death.date = vaccine.date

where death.continent is not null

group by
death.continent,
death.location,
death.date
) as subquery

order by 
location, date


--using CTE to see the percentage of people vaccinated on previous query
with populationVSvaccination as (
select
continent,
location,
date,
population,
new_vaccinations,
sum(cast(new_vaccinations as bigint)) over
	(partition by location order by date)
		as rolling_new_vaccinations

from
(
select distinct
death.continent,
death.location,
death.date,
min(death.population) as population,
min(vaccine.new_vaccinations) as new_vaccinations

from PortfolioProject..covid_deaths as death
join PortfolioProject..covid_vaccination as vaccine
on death.location = vaccine.location
and death.date = vaccine.date

where death.continent is not null

group by
death.continent,
death.location,
death.date
) as subquery
)
select
populationVSvaccination.*,
cast(100.0 * populationVSvaccination.rolling_new_vaccinations / 
		populationVSvaccination.population as decimal(10,2))
			as vaccinated_pct
from populationVSvaccination
order by location, date


--Using temp table for the previous equation
drop table if exists #populationVSvaccination

create table #populationVSvaccination(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population bigint,
new_vaccinations int
)

insert into #populationVSvaccination(
continent,
location,
date,
population,
new_vaccinations
)

select distinct
death.continent,
death.location,
death.date,
min(death.population) as population,
min(vaccine.new_vaccinations) as new_vaccinations

from PortfolioProject..covid_deaths as death
join PortfolioProject..covid_vaccination as vaccine
on death.location = vaccine.location
and death.date = vaccine.date

where death.continent is not null
and death.population is not null
and vaccine.new_vaccinations is not null

group by
death.continent,
death.location,
death.date

select *,
sum(cast(new_vaccinations as bigint)) over
	(partition by location 
		order by date) as rolling_new_vaccinations,
cast(100 * sum(cast(new_vaccinations as bigint)) over
	(partition by location 
		order by date)  / population as decimal(10,2))
				as vaccinated_pct

from #populationVSvaccination
order by location, date

drop table #populationVSvaccination


--Crete view to store data for visualization
drop view if exists populationVSvaccination
go
create view populationVSvaccination as

select
death.continent,
death.location,
death.date,
min(death.population) as population,
min(vaccine.new_vaccinations) as new_vaccinations,
sum(cast(min(vaccine.new_vaccinations) as bigint)) over
	(partition by death.location order by death.date)
		as rolling_new_vaccinations,
cast(100 * sum(cast(min(vaccine.new_vaccinations) as bigint)) over
	(partition by death.location order by death.date) / 
		min(death.population) as decimal(10,2))
			as vaccinated_pct

from PortfolioProject..covid_deaths as death
join portfolioProject..covid_vaccination as vaccine
on death.location = vaccine.location
and death.date = vaccine.date

where death.continent is not null

group by
death.location,
death.continent,
death.date