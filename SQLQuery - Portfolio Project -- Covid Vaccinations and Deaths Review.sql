/** Portfolio Project -- Covid Vaccinations and Deaths Review */


/* initial look at the imported data */
select *
from CovidDeaths

select * 
from CovidVacinations


--select the data we are using
select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
order by 1,2


-- looking at total cases vs total deaths
select 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	population, 
	(total_deaths/total_cases) * 100 as DeathPercentage
from CovidDeaths
order by 1,2


-- looking at total cases vs total deaths  (likelyhood of dying if you live in US = 1.08%)
select 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	population, 
	(total_deaths/total_cases) * 100 as DeathPercentage
from CovidDeaths
where location like '%United States%'
order by 1,2


-- looking at total cases vs Population  (percent of population has contracted Covid = 29.67%)   likelihood of catching
select 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	population, 
	(total_cases/population) * 100 as CasePercentage
from CovidDeaths
where location = 'United States'
order by 1,2


select 
	location, 
	sum(cast(new_deaths as int)) as TotalDeathCount
from CovidDeaths
where continent is null
 and location not in ('world','European Union','International','high income',
                      'upper middle income','lower middle income','low income')
Group by location
order by TotalDeathCount desc




-- looking at Countries with the Highest infection rate compared to population  = Cypress at 70%
select 
	location, 
	Population,
	date,
	MAX(cast(total_cases as int)) as HightestInfectionCount, 
	max(cast(total_cases as int)/population) * 100 as PercentPopulationInfected
from CovidDeaths
group by location, population, date
order by PercentPopulationInfected desc


-- Showing Countries with Highest Death Count per Population  =  US at 1,090,218
select 
	location, 
--	Population,
	MAX(cast(total_deaths as int)) as TotalDeathCount 
--	max(total_deaths/population) * 100 as PercentPopulationDeaths
from CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc


--- lets break it down by continent
select 
	continent, 
--	Population,
	MAX(cast(total_deaths as int)) as TotalDeathCount 
--	max(total_deaths/population) * 100 as PercentPopulationDeaths
from CovidDeaths
--where continent is null
group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS
select 
	date, 
	SUM(new_cases) as total_cases, 
	sum(cast(new_deaths as int)) as total_deaths, 
	(sum(cast(new_deaths as int))/sum(new_cases)) * 100 as DeathPercentage
from CovidDeaths
where continent is not null
group by date
order by 1,2



-- without date groupings
select 
	SUM(new_cases) as total_cases, 
	sum(cast(new_deaths as int)) as total_deaths, 
	(sum(cast(new_deaths as int))/sum(new_cases)) * 100 as DeathPercentage
from CovidDeaths
where continent is not null
--group by date
order by 1,2


select 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations

from CovidDeaths d
Join CovidVacinations v
on d.location = v.location
and d.date = v.date
where d.continent is not null
order by 1,2,3


-- add rolling count of new vacinations
select 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(convert(bigint,v.new_vaccinations)) 
		over(partition by d.location order by d.location, d.date) as cum_total
from CovidDeaths d
Join CovidVacinations v
on d.location = v.location
and d.date = v.date
where d.continent is not null
order by 1,2,3


---USE CTE
with popVvacs(continent, location, date, population, new_vaccinations, cum_total)
as (
select 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(convert(bigint,v.new_vaccinations)) 
		over(partition by d.location order by d.location, d.date) as cum_total
from CovidDeaths d
Join CovidVacinations v
on d.location = v.location
and d.date = v.date
where d.continent is not null
)
select *, (cum_total/population)*100 as cum_pct
from popVvacs
order by 1,2,3



-- Using Temp table
Drop table if  exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	cum_total  numeric
 )
insert Into #PercentPopulationVaccinated
select 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(convert(bigint,v.new_vaccinations)) 
		over(partition by d.location order by d.location, d.date) as cum_total
from CovidDeaths d
Join CovidVacinations v
on d.location = v.location
and d.date = v.date
where d.continent is not null

select *, (cum_total/population)*100 as cum_pct
from #PercentPopulationVaccinated




---- Creating View to store data for later visualizations
Create View PercentPopulationVaccinated as
select 
	d.continent,
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	sum(convert(bigint,v.new_vaccinations)) 
		over(partition by d.location order by d.location, d.date) as cum_total
from CovidDeaths d
Join CovidVacinations v
on d.location = v.location
and d.date = v.date
where d.continent is not null