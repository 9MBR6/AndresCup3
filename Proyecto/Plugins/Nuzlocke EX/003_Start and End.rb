#-------------------------------------------------------------------------------
# Reload challenge data upon save reload
#-------------------------------------------------------------------------------
class PokemonLoadScreen
  alias __challenge__pbStartLoadScreen pbStartLoadScreen unless method_defined?(:__challenge__pbStartLoadScreen)
  def pbStartLoadScreen
    ret = __challenge__pbStartLoadScreen
    ChallengeModes.toggle(true) if ChallengeModes.running?
    return ret
  end
end

alias __challenge__pbTrainerName pbTrainerName unless defined?(__challenge__pbTrainerName)
def pbTrainerName(*args)
  ret = __challenge__pbTrainerName(*args)
  ChallengeModes.reset
  $PokemonGlobal.challenge_state = {}
  return ret
end

#-------------------------------------------------------------------------------
# Starts challenge only after obtaining a Pokeball
#-------------------------------------------------------------------------------
class PokemonBag
  alias __challenge__add add unless method_defined?(:__challenge__add)
  def add(*args)
    ret = __challenge__add(*args)
    item = args[0]
    return ret if !$PokemonGlobal || !$PokemonGlobal.challenge_qued || !GameData::Item.get(item).is_poke_ball?
    ChallengeModes.begin_challenge
    pbMessage(_INTL("Ahora que tienes pokebolas ha comenzado el modo nuzlocke!"))
    return ret
  end
end


#-------------------------------------------------------------------------------
# Add Game Over methods
#-------------------------------------------------------------------------------
alias __challenge__pbStartOver pbStartOver unless defined?(__challenge__pbStartOver)
def pbStartOver(*args)
  return __challenge__pbStartOver(*args) if !ChallengeModes.on?
  resume = false
  pbEachPokemon do |pkmn, _|
    next if pkmn.fainted? || pkmn.egg?
    resume = true
    break
  end
  if resume && !ChallengeModes.on?(:GAME_OVER_WHITEOUT)
    loop do
      pbMessage("\\w[]\\wm\\c[8]\\l[3]" + 
        _INTL("Has palmao, pero todavía queda esperanza, usa los pokémon de tu PC para recomponer tu equipo y vuelve a intentarlo."))
      pbFadeOutIn(99999) {
        scene = PokemonStorageScene.new
        screen = PokemonStorageScreen.new(scene, $PokemonStorage)
        screen.pbStartScreen(0)
      }
      break if $player.able_pokemon_count != 0
    end
  else
    pbMessage("\\w[]\\wm\\c[8]\\l[3]" + 
      _INTL("Todos tus pokémon han murido, puedes volver a empezar una partida nueva, o hablar con Sasi si quieres participar en el torneo."))
    ChallengeModes.set_loss
  end
  return __challenge__pbStartOver(*args)
end