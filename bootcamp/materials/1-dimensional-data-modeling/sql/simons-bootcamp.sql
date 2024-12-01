select * from  player_seasons;
--
drop type season_stats;
create type season_stats as (
    season INTEGER,
    gp INTEGER,
    pts REAL,
    reb REAL,
    ast REAL 
);

--
create type scoring_class  AS ENUM ('star','good','average','bad');
--
drop table players;
create table  players (
    player_name text,
    height text,
    college text,
    country text,
    draft_year text,
    draft_round text,
    draft_number text,
    season_stats season_stats[],
    scoring_class scoring_class,
    years_since_last_season integer,
    current_season integer,
    is_active BOOLEAN,
    primary key (player_name, current_season)
);
--
--
insert into players
with yesterday as (
    select * from players
    where current_season = 2000
),
today as (
    select * from player_seasons
    where season = 2001
)
select  
    COALESCE(t.player_name, y.player_name) as player_name,
    COALESCE(t.height, y.height) as height,
    COALESCE(t.college, y.college) as college,
    COALESCE(t.country, y.country) as country,
    COALESCE(t.draft_year, y.draft_year) as draft_year,
    COALESCE(t.draft_round, y.draft_round) as draft_round,
    COALESCE(t.draft_number, y.draft_number) as draft_number,
    CASE 
         WHEN y.season_stats IS NULL THEN 
            array[ row( t.season, t.gp, t.pts, t.reb, t.ast)::season_stats ]
         WHEN t.season is not null THEN 
            y.season_stats || array[ row( t.season, t.gp, t.pts, t.reb, t.ast)::season_stats ]
         ELSE y.season_stats
    END  as season_stats,
    case    WHEN t.season IS NOT NULL THEN  
                (case   WHEN t.pts > 20 THEN 'star'
                        WHEN t.pts > 15 THEN 'good'
                        WHEN t.pts > 10 THEN 'average' 
                        ELSE 'bad'
                        END )::scoring_class
            ELSE y.scoring_class 
    END AS scoring_class,
    case    when t.season is not null then 0
            else  y.years_since_last_season + 1
    end as years_since_last_season,
    COALESCE ( t.season, y.current_season + 1) as current_season
from today t full outer join yesterday y on t.player_name = y.player_name
;

select * from players;


with unnested as (
    select player_name,
        UNNEST (season_stats)::season_stats as season_stats
    from players
    where current_season = 2001
    
    )
select player_name,
        (season_stats::season_stats).*
from unnested;