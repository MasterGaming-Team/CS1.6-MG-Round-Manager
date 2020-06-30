#include <amxmodx>
#include <amxmisc>
#include <mg_round_manager_const>
#include <reapi>

#define PLUGIN "[MG] Round Manager"
#define VERSION "1.0"
#define AUTHOR "Vieni"

#define TASKCOUNT 512

new gRoundTime

new retValue

new gForwardRoundEnd, gForwardRoundRespawn, gForwardRoundStart

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR)

    gForwardRoundEnd = CreateMultiForward("mg_fw_round_end", ET_CONTINUE, FP_CELL)
    gForwardRoundRespawn = CreateMultiForward("mg_fw_round_respawn", ET_CONTINUE)
    gForwardRoundStart = CreateMultiForward("mg_fw_round_start", ET_CONTINUE)

    set_task(1.0, "event_count", TASKCOUNT)
}

public plugin_natives()
{
    register_native("mg_rmanager_roundtime_get", "native_rmanager_roundtime_get")
    register_native("mg_rmanager_roundtime_set", "native_rmanager_roundtime_set")

    register_native("mg_rmanager_time_get", "native_rmanager_time_get")
    register_native("mg_rmanager_time_set", "native_rmanager_time_set")
    register_native("mg_rmanager_time_add", "native_rmanager_time_add")
}

public event_count()
{
    gRoundTime--

    if(gRoundTime == 0)
    {
        roundEnd(MG_ROUND_END_TIME)
    }

    set_task(1.0, "event_count", TASKCOUNT)
}

public roundEnd(type)
{
    ExecuteForward(gForwardRoundEnd, retValue, type)

    if(retValue = MG_ROUND_END_RET_HANDLED)
        return
rg_
    set_task(0.5, "roundRespawn")
}

public roundRespawn()
{
    ExecuteForward(gForwardRoundRespawn, retValue)
}

public roundStart()
{
    ExecuteForward(gForwardRoundStart, retValue)
}