Team = {
  max = 3,
  size = {}, -- [team #]: number of entities
  colors = {'red','yellow','green','blue'},
  teams_left = 0
}
local last_team_joined = 0

System(All("Team", Some("Health")), {
  add = function(ent)
    -- assign to a team
    last_team_joined = last_team_joined % 3 + 1
    ent.Team = last_team_joined

    local team = ent.Team
    if not Team.size[team] then Team.size[team] = 1
    else Team.size[team] = Team.size[team] + 1 end
    print_r(Team.size)
  end,
  update = function(ent, dt)
    local hx, team, bs = ent.Health, ent.Team, ent.BirdSprite
    -- entity dies 
    if hx and hx.current <= 0 then 
      Team.size[team] = Team.size[team] - 1 
      -- move to next team
      ent.Team = team % 3 + 1
      team = ent.Team
      if not Team.size[team] then Team.size[team] = 1
      else Team.size[team] = Team.size[team] + 1 end
      hx.current = hx.max
    end
  end,
  remove = function(ent)
    local team = ent.Team
    Team.size[team] = Team.size[team] - 1
  end
})

