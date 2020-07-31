#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <mg_round_manager_const>
#include <reapi>

#define PLUGIN "[MG] Round Manager"
#define VERSION "1.0"
#define AUTHOR "Vieni"

#define TASKCOUNT 1

new gDefRoundTime
new gRoundTime
new bool:gRoundActive = false

new retValue, gMaxPlayers, gMsgRoundTime

new gForwardRoundEndPre, gForwardRoundEndPost, gForwardRoundRespawn, gForwardRoundStartPost

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    gMsgRoundTime = get_user_msgid("RoundTime")
    gMaxPlayers = get_maxplayers()
    gRoundTime = gDefRoundTime = get_cvar_num("mp_roundtime")

    RegisterHamPlayer(Ham_Spawn, "fw_player_spawn_post", 1)
    RegisterHamPlayer(Ham_Killed, "fw_player_killed_post", 1)
    RegisterHamPlayer(Ham_TakeDamage, "fw_player_takedamage_pre")

    gForwardRoundEndPre = CreateMultiForward("mg_fw_round_end_pre", ET_CONTINUE, FP_CELL)
    gForwardRoundEndPost = CreateMultiForward("mg_fw_round_end_post", ET_CONTINUE, FP_CELL)
    gForwardRoundRespawn = CreateMultiForward("mg_fw_round_respawn", ET_CONTINUE)
    gForwardRoundStartPost = CreateMultiForward("mg_fw_round_start_post", ET_CONTINUE)

    event_count()
}

public plugin_natives()
{
    register_native("mg_rmanager_roundend_trigger", "native_rmanager_roundend_trigger")

    register_native("mg_rmanager_roundtime_get", "native_rmanager_roundtime_get")
    register_native("mg_rmanager_roundtime_set", "native_rmanager_roundtime_set")

    register_native("mg_rmanager_time_get", "native_rmanager_time_get")
    register_native("mg_rmanager_time_set", "native_rmanager_time_set")
    register_native("mg_rmanager_time_add", "native_rmanager_time_add")
}

public event_count()
{
    gRoundTime--

    message_begin(MSG_BROADCAST, gMsgRoundTime)
    {
        write_short(gRoundTime+1)
    }
    message_end()

    if(gRoundTime == 0)
    {
        roundEnd(MG_ROUND_END_TIME)
        return
    }

    set_task(1.0, "event_count", TASKCOUNT)
}

public roundEnd(type)
{
    ExecuteForward(gForwardRoundEndPre, retValue, type)

    if(retValue == MG_ROUND_END_RET_HANDLED)
        return

    gRoundActive = false

    remove_task(TASKCOUNT)

    rg_balance_teams()

    ExecuteForward(gForwardRoundEndPost, retValue, type)

    set_task(1.5, "roundRespawn")
}

public roundRespawn()
{
    for(new i = 1; i <= gMaxPlayers; i++)
    {
        if(!is_user_connected(i))
            continue
        
        rg_round_respawn(i)
    }
    
    ExecuteForward(gForwardRoundRespawn, retValue)

    set_task(1.0, "roundStart")
}

public roundStart()
{
    gRoundActive = true
    gRoundTime = gDefRoundTime

    if(!task_exists(TASKCOUNT))
        event_count()
    
    ExecuteForward(gForwardRoundStartPost, retValue)
}

public native_rmanager_roundend_trigger(plugin_id, param_num)
{
    new type = get_param(1)

    roundEnd(type)
    return true
}

public native_rmanager_roundtime_get(plugin_id, param_num)
{
    return gDefRoundTime
}

public native_rmanager_roundtime_set(plugin_id, param_num)
{
    new lTime = get_param(1)

    gDefRoundTime = lTime

    return true
}

public native_rmanager_time_get(plugin_id, param_num)
{
    return gRoundTime
}

public native_rmanager_time_set(plugin_id, param_num)
{
    new lTime = get_param(1)

    gRoundTime = lTime

    return true
}

public native_rmanager_time_add(plugin_id, param_num)
{
    new lTime = get_param(1)

    gRoundTime += lTime

    return gRoundTime
}

public fw_player_spawn_post(id)
{
    checkRoundEnd()

    if(!is_user_alive(id))
        return

    message_begin(MSG_BROADCAST, gMsgRoundTime, _, id)
    {
        write_short(gRoundTime+1)
    }
    message_end()
}

public fw_player_killed_post()
{
    checkRoundEnd()
}

public fw_player_takedamage_pre(victim, inflictior, attacker, Float:damage, damagebits)
{
    if(!gRoundActive)
    {
        SetHamParamFloat(4, 0.0)
    }
}

public client_disconnected()
{
    checkRoundEnd()
}

checkRoundEnd()
{
    if(!gRoundActive)
        return
    
    if(!getCtCount() && !getTrCount())
    {
        roundEnd(MG_ROUND_END_DRAW)
        return
    }

    if(!getTrCount())
    {
        roundEnd(MG_ROUND_END_CT_WIN)
        return
    }

    if(!getCtCount())
    {
        roundEnd(MG_ROUND_END_TR_WIN)
        return
    }
}

getCtCount()
{
    new count

    for(new i = 1; i <= gMaxPlayers; i++)
    {
        if(!is_user_alive(i))
            continue

        if(cs_get_user_team(i) == CS_TEAM_CT)
            count++
    }

    return count
}

getTrCount()
{
    new count

    for(new i = 1; i <= gMaxPlayers; i++)
    {
        if(!is_user_alive(i))
            continue

        if(cs_get_user_team(i) == CS_TEAM_T)
            count++
    }

    return count
}