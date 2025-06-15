# This is a Python scripts file from Home Assistant
# VERSÃO EM USO 

output = {}  # Precisa ser definido no início
skipped_entities = []  # Definição da variável skipped_entities

def process_light_group(group_obj):
    # Verifica se é uma luz individual ou um grupo
    try:
        # Usa apenas operadores in e acesso direto
        if "entity_id" in group_obj and "action" in group_obj:
            return [{"entity": group_obj["entity_id"], "config": group_obj}]
    except:
        pass
    
    # É um grupo, processa recursivamente
    all_lights = []
    for entity_id, config in group_obj.items():
        try:
            if "action" in config:  # Verifica se tem action diretamente
                data = {}
                if "data" in config:
                    data = config["data"]
                    
                all_lights.append({
                    "entity": entity_id,
                    "action": config["action"],
                    "data": data
                })
            else:
                # É um subgrupo, processa recursivamente
                sub_lights = process_light_group(config)
                all_lights.extend(sub_lights)
        except:
            continue
            
    return all_lights

def process_lights_shelfs(lights_obj):
    # 1) Extrai cópia rasa do grupo original (ou {} se não existir)
    orig_group = lights_obj.get("light.tv_shelf_group") or {}
    tv_shelf_group_obj = { key: val for key, val in orig_group.items() }

    # 2) Processa só as 5 luzes de prateleira nesse objeto
    for i in range(1, 6):
        lid = f"light.wled_tv_shelf_{i}"
        ib  = f"input_boolean.wled_tv_shelf_{i}"

        if lid in tv_shelf_group_obj:
            st = hass.states.get(ib)
            if st and st.state == "off":
                # força desligar
                tv_shelf_group_obj[lid] = {"action": "turn_off"}
            else:
                # tenta resgatar a ação original
                original_entry = orig_group.get(lid, {})
                original_action = original_entry.get("action")
                original_data   = original_entry.get("data", {})

                if original_action:
                    tv_shelf_group_obj[lid] = {
                        "action": original_action,
                        "data": original_data
                    }
                # se não havia action, não mexe

    # 3) Reatribui o grupo modificado de volta no objeto original
    lights_obj["light.tv_shelf_group"] = tv_shelf_group_obj

    # 4) Retorna o objeto completo (com todas as outras entradas intactas)
    return lights_obj


def update_lights(lights_obj):
    # Processa todas as luzes

    output["lights_obj1"] = lights_obj.copy();

    # if("light.tv_shelf_group" in lights_obj):
    #     lights_obj = process_lights_shelfs(lights_obj)

    # return lights_obj;

    lights_to_update = process_light_group(lights_obj)

    output["lights_obj2"] = lights_to_update.copy();
    
    # Lista para armazenar todas as luzes que foram atualizadas
    updated_entities = []
    start_states = {}
    
    # Captura estados iniciais
    for light_config in lights_to_update:
        try:
            entity = light_config["entity"]
            state = hass.states.get(entity)
            if state:
                start_states[entity] = {
                    "state": state.state,
                    "attributes": state.attributes.copy()
                }
        except:
            continue
    
    # Executa as atualizações
    for light_config in lights_to_update:
        try:
            entity = light_config["entity"]
            action = light_config["action"]
            # data = light_config.get("data", {})
            # copia para não alterar o original compartilhado
            data = light_config.get("data", {}).copy()
            # Adiciona transição padrão de 2 segundos se não especificado
            if "transition" not in data:
                data["transition"] = 2
            
            # Obtém o estado atual da luz
            current_state = hass.states.get(entity)
            
            if current_state is None:
                raise Exception(f"Entidade {entity} não encontrada")
                
            # Verifica se precisa atualizar
            needs_update = False
            skip_reason = "Estado já correto"
            
            if action == "turn_on":
                if current_state.state == "off":
                    needs_update = True
                else:
                    # Verifica se algum atributo é diferente
                    current_attrs = current_state.attributes
                    for key, value in data.items():
                        if key == "entity_id":
                            continue
                        
                        attr_key = key
                        if key == "transition":
                            continue
                        if key == "brightness_pct":
                            attr_key = "brightness"
                            brightness_percentage = float(hass.states.get("input_number.living_scene_brightness_percentage").state)
                            value = int((value * brightness_percentage / 100))
                            value = min(value, 100)
                            value = max(value, 1)
                            value_255 = int((value * 255 / 100))
                            current_value = current_attrs.get(attr_key, 0)
                            brightness_percent_diff = abs(current_value - value_255) / 255 * 100
                            # Atualiza o valor em data para ser enviado ao serviço
                            data[key] = value
                            if brightness_percent_diff <= 1:
                                continue
                        elif key == "brightness":
                            brightness_percentage = float(hass.states.get("input_number.living_scene_brightness_percentage").state)
                            value = int((value * brightness_percentage / 100))
                            value = min(value, 255)
                            value = max(value, 1)
                            current_value = current_attrs.get("brightness", 0)
                            brightness_diff = abs(current_value - value)
                            # Atualiza o valor em data para ser enviado ao serviço
                            data[key] = value
                            if brightness_diff <= 2:
                                continue
                        
                        # Tratamento especial para rgbw_color e rgb_color
                        if key in ["rgbw_color", "rgb_color"]:
                            current_value = current_attrs.get(attr_key)
                            if current_value and tuple(value) == current_value:
                                continue
                            if current_attrs.get(attr_key) != tuple(value):
                                needs_update = True
                                skip_reason = f"Atributo {key} diferente: atual={current_attrs.get(attr_key)}, desejado={tuple(value)}"
                                break
                        # Tratamento especial para effect (ignorar case)
                        elif key == "effect":
                            current_value = str(current_attrs.get(attr_key, "")).lower()
                            desired_value = str(value).lower()
                            if current_value == desired_value:
                                continue
                            needs_update = True
                            skip_reason = f"Atributo {key} diferente: atual={current_attrs.get(attr_key)}, desejado={value}"
                            break
                        # Para outros atributos
                        elif current_attrs.get(attr_key) != value:
                            needs_update = True
                            skip_reason = f"Atributo {key} diferente: atual={current_attrs.get(attr_key)}, desejado={value}"
                            break
                            
            elif action == "turn_off" and current_state.state != "off":
                needs_update = True
                
            # Só atualiza se necessário
            if needs_update:
                if action == "turn_on":
                    data["entity_id"] = entity
                    hass.services.call("light", "turn_on", data)
                    updated_entities.append({
                        "entity": entity,
                        "target_state": "on",
                        "target_attrs": data,
                        "reason": skip_reason
                    })
                elif action == "turn_off":
                    hass.services.call("light", "turn_off", {"entity_id": entity})
                    updated_entities.append({
                        "entity": entity,
                        "target_state": "off",
                        "target_attrs": {},
                        "reason": "Estado atual: on, necessário desligar"
                    })
            else:
                skipped_entities.append({
                    "entity": entity,
                    "reason": skip_reason,

                })
                
        except Exception as e:
            hass.services.call("persistent_notification", "create", {
                "title": "Erro ao executar ação",
                "message": f"Não foi possível executar a ação {action} para {entity}: {str(e)}"
            })
            output["log"] = f"Erro ao executar ação: {action} para {entity} - {str(e)}"

    return updated_entities

def find_and_update(current_dict, target_id, config):
    if target_id in current_dict:
        # Se o valor do grupo NÃO tem "action", é um grupo de entidades
        if "action" not in current_dict[target_id]:
            # Atualiza todas as filhas (entidades ou subgrupos)
            for k, v in current_dict[target_id].items():
                # Se for uma entidade (tem "action"), atualiza
                if "action" in v:
                    current_dict[target_id][k] = config
                # Se for subgrupo, chama recursivamente
                else:
                    find_and_update(current_dict[target_id], k, config)
        else:
            # Se for entidade, atualiza normalmente
            current_dict[target_id] = config
        return True

    for key, value in current_dict.items():
        try:
            if value.items():
                if find_and_update(value, target_id, config):
                    return True
        except:
            continue
    return False

def update_specific_light(luzes_dict, light_ids, config):
    if isinstance(light_ids, str):
        light_ids = [light_ids]
    
    updated = False
    for light_id in light_ids:
        if find_and_update(luzes_dict, light_id, config):
            updated = True
            
    return updated

#Definição de variáveis iniciais
luzesOriginal = {
    "light.kitchen_led": {"action": "turn_off"},
    "light.kitchen_sink_light": {"action": "turn_off"},
    "light.kitchen_sink_light_old": {"action": "turn_off"},
    "light.window_led_strip": {"action": "turn_off"},
    "light.wled_tv_shelf_main": {"action": "turn_on",
            "data": {
                "brightness_pct": 100,
            }
        },
    "light.tv_shelf_group": {
        "light.wled_tv_shelf_1": {"action": "turn_off"},
        "light.wled_tv_shelf_2": {"action": "turn_off"},
        "light.wled_tv_shelf_3": {"action": "turn_off"},
        "light.wled_tv_shelf_4": {"action": "turn_off"},
        "light.wled_tv_shelf_5": {"action": "turn_off"}
    },
    "light.living_temperature_lights": {
        "light.chaise_light": {"action": "turn_off"},
        "light.shoes_light": {"action": "turn_off"},
        "light.corredor_door_light": {"action": "turn_off"},
        "light.entrance_dining_light": {"action": "turn_off"},
        "light.living_entry_door_light": {"action": "turn_off"},
        "light.living_fireplace_spot": {"action": "turn_off"}
    },
    "light.color_lights": {
        "light.tv_light": {"action": "turn_off"},
        "light.color_lights_without_tv_light": {
            "light.dining_table_light": {"action": "turn_off"},
            "light.living_art_wall_light": {"action": "turn_off"},
            "light.desk_light": {"action": "turn_off"},
            "light.corner_light": {"action": "turn_off"},
            "light.tripod_lamp": {"action": "turn_off"},
            "light.zigbee_hub_estante_lights": {
                "light.estante_1_light": {"action": "turn_off"},
                "light.estante_2_light": {"action": "turn_off"}
            }
        }
    }
}

luzes = luzesOriginal.copy()

start_time = datetime.datetime.now().timestamp() * 1000
scene = hass.states.get("input_select.living_scene")
if scene is None:
    hass.services.call("persistent_notification", "create", {
        "title": "Erro na Execução da Cena",
        "message": "O input_select.living_scene não foi encontrado."
    })
    output["log"] = "O input_select.living_scene não foi encontrado."
    scene = "unknown"
else:
    scene = scene.state
output["scene"] = scene

sun = hass.states.get("sun.sun")
next_setting = datetime.datetime.fromisoformat(sun.attributes.get("next_setting"))
current_time = datetime.datetime.now(next_setting.tzinfo)
one_hour_seconds = 60*60  # 60 minutos * 60 segundos

output["current_time"] = current_time.isoformat()
output["next_setting_sun"] = next_setting.isoformat()

if sun.state == "above_horizon":
    two_hours_before = next_setting - datetime.timedelta(seconds=2*one_hour_seconds)
    one_hour_before = next_setting - datetime.timedelta(seconds=one_hour_seconds)
    eighteen_hours_before = next_setting - datetime.timedelta(seconds=18*one_hour_seconds)
    
    output["one_hour_before"] = one_hour_before.isoformat()
    output["two_hours_before"] = two_hours_before.isoformat()
    output["eighteen_hours_before"] = eighteen_hours_before.isoformat()

    if current_time > one_hour_before:
        time_of_day = "sunset"
    elif current_time > two_hours_before:
        time_of_day = "pre_sunset"
    elif current_time < eighteen_hours_before:
        time_of_day = "nighttime"
    else:
        time_of_day = "daytime"
else:
    time_of_day = "nighttime"

kitchen_extra_brightness = hass.states.get("input_boolean.kitchen_extra_brightness").state


output["time_of_day"] = time_of_day

hyperion_running = hass.states.get("binary_sensor.living_tv_hyperion_running_condition_for_the_scene").state
output["hyperion_running"] = hyperion_running

# Movimento Cozinha
if time_of_day == "daytime" or time_of_day == "pre_sunset" :
    sink_rgbw_color = [0, 0, 0, 255]
else:
    sink_rgbw_color = [230, 170, 30, 150]
if (
    hass.states.get("binary_sensor.kitchen_espresence").state == "on"
    or hass.states.get("binary_sensor.kitchen_presence_occupancy").state == "on"
):
    if((scene == "calm night" or scene == "normal" or scene == "off") and kitchen_extra_brightness == "off"):
        luzes["light.kitchen_sink_light"] = {
            "action": "turn_on",
            "data": {
                "brightness_pct": 60,
                "rgbw_color": sink_rgbw_color,
                "effect": "solid"
            }
        }
    else:
        luzes["light.kitchen_sink_light"] = {
            "action": "turn_on",
            "data": {
                "brightness_pct": 100,
                "rgbw_color": sink_rgbw_color,
                "effect": "solid"
            }
        }

    luzes["light.kitchen_sink_light_old"] = {
        "action": "turn_on",
        "data": {
            "brightness_pct": 20,
            "transition": 1
        }
    }
else:
    hass.services.call("input_boolean", "turn_off", {"entity_id": "input_boolean.kitchen_extra_brightness"})
    if scene != "off":
        luzes["light.kitchen_sink_light"] = {
        "action": "turn_on",
        "data": {
                "brightness_pct": 10,
                "rgbw_color": sink_rgbw_color,
                "effect": "solid"
            }
        }
        luzes["light.kitchen_sink_light_old"] = {
            "action": "turn_on",
            "data": {
                "brightness_pct": 10,
                "transition": 1
            }
        }

# Cenas
if hass.states.get("input_boolean.living_scene_auto").state == "on":
    if scene != "preset":
        hass.services.call("scene_presets", "stop_all_dynamic_scenes")
    else:
        luzes = {"light.living_temperature_lights" : {"action": "turn_off"}}

    if scene == "off":
        luzes["light.living_temperature_lights"] = {"action": "turn_off"}
        luzes["light.color_lights"] = {"action": "turn_off"}
        luzes["light.window_led_strip"] = {"action": "turn_off"}
        luzes["light.kitchen_led"] = {"action": "turn_off"}

    if scene == "calm night":
        if time_of_day == "daytime"  or time_of_day == "pre_sunset":
            calm_dining_color_temp = 200
            update_specific_light(luzes, "light.kitchen_led", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 50,
                    "rgbw_color": [0, 0, 0, 255],
                    "effect": "solid",
                }
            })
            update_specific_light(luzes, "light.tripod_lamp", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 10,
                    "color_temp": 200,
                }
            })
        else:
            if hyperion_running == "off":
                update_specific_light(luzes, "light.tv_shelf_group", {
                    "action": "turn_on",
                    "data": {
                        "brightness_pct": 2,
                        "rgbw_color": [255, 158, 64, 255],
                        "effect": "solid"
                    }
                })
                if("light.tv_shelf_group" in luzes):
                    luzes = process_lights_shelfs(luzes)
            else:
                update_specific_light(luzes, "light.tv_shelf_group", {
                    "action": "turn_off"
                })
            calm_dining_color_temp = 365
            update_specific_light(luzes, "light.window_led_strip", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 17,
                    "effect": "solid",
                    "rgb_color": [203, 176, 128],
                }
            })
            
            update_specific_light(luzes, [
                "light.entrance_dining_light",
                "light.living_entry_door_light",
                "light.living_fireplace_spot"
            ], {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 10,
                    "color_temp": 426,
                }
            })

            update_specific_light(luzes, "light.desk_light", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 5,
                    "color_temp": 377,
                }
            })

            update_specific_light(luzes, [
                "light.shoes_light",
                "light.tv_light",
                "light.chaise_light",
                "light.corredor_door_light"
            ], {
                "action": "turn_off"
            })

            update_specific_light(luzes, "light.tripod_lamp", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 10,
                    "color_temp": 400,
                }
            })

            update_specific_light(luzes, "light.zigbee_hub_estante_lights", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 8,
                    "color_temp": 359,
                }
            })

            update_specific_light(luzes, "light.living_art_wall_light", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 10,
                    "color_temp": 335,
                }
            })

            update_specific_light(luzes, "light.kitchen_led", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 50,
                    "rgbw_color": [230, 170, 30, 150],
                    "effect": "solid",
                }
            })

        # Verifica presença na área de jantar
        if hass.states.get("binary_sensor.dining_espresence").state == "on":
            update_specific_light(luzes, "light.dining_table_light", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 30,
                    "color_temp": calm_dining_color_temp,
                }
            })
        else:
            update_specific_light(luzes, "light.dining_table_light", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 10,
                    "color_temp": calm_dining_color_temp,
                }
            })

    if scene == "normal":
        if time_of_day == "daytime" or time_of_day == "pre_sunset":
            if hyperion_running == "off":
                update_specific_light(luzes, "light.tv_light", {
                    "action": "turn_on",
                    "data": {
                        "brightness_pct": 50,
                        "color_temp": 224
                    }
                })
                update_specific_light(luzes, "light.wled_tv_shelf_4", {
                    "action": "turn_on",
                    "data": {
                        "brightness_pct": 20,
                        "rgbw_color": [7, 106, 168, 255],
                        "effect": "solid"
                    }
                })

            else:
                update_specific_light(luzes, "light.tv_light", {
                    "action": "turn_off"
                })
                update_specific_light(luzes, "light.tv_shelf_group", {
                    "action": "turn_off"
                })
            
            update_specific_light(luzes, "light.dining_table_light", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 100,
                    "color_temp": 206
                }
            })

            update_specific_light(luzes, "light.corner_light", {
                "action": "turn_off"
            })

            update_specific_light(luzes, "light.desk_light", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 40,
                    "color_temp": 199,
                    "transition": 2
                }
            })

            update_specific_light(luzes, [
                "light.corredor_door_light",
                "light.entrance_dining_light",
                "light.living_entry_door_light"
            ], {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 60,
                    "color_temp": 250
                }
            })

            update_specific_light(luzes, "light.shoes_light", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 50,
                    "color_temp": 250
                }
            })

            update_specific_light(luzes, [
                "light.chaise_light",
                "light.window_led_strip"
            ], {
                "action": "turn_off"
            })

            update_specific_light(luzes, "light.living_art_wall_light", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 60,
                    "color_temp": 196
                }
            })

            update_specific_light(luzes, "light.tripod_lamp", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 49,
                    "color_temp": 206
                }
            })

            update_specific_light(luzes, "light.living_fireplace_spot", {
                "action": "turn_off"
            })

            update_specific_light(luzes, "light.zigbee_hub_estante_lights", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 55,
                    "color_temp": 198
                }
            })

            update_specific_light(luzes, "light.kitchen_led", {
                "action": "turn_on",
                "data": {
                    "rgbw_color": [0, 0, 0, 255],
                    "brightness_pct": 50
                }
            })
        else:
            if hyperion_running == "off":
                update_specific_light(luzes, "light.tv_light", {
                    "action": "turn_on",
                    "data": {
                        "brightness_pct": 51,
                        "color_temp": 394
                    }
                })
                update_specific_light(luzes, "light.tv_shelf_group", {
                    "action": "turn_on",
                    "data": {
                        "brightness_pct": 20,
                        "rgbw_color": [255, 158, 64, 255],
                        "effect": "solid"
                    }
                })
            else:
                update_specific_light(luzes, "light.tv_light", {
                    "action": "turn_off"
                })

            update_specific_light(luzes, "light.color_lights_without_tv_light", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 51,
                    "color_temp": 394
                }
            })

            update_specific_light(luzes, "light.corner_light", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 30,
                    "color_temp": 394
                }
            })

            update_specific_light(luzes, "light.window_led_strip", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 40,
                    "rgb_color": [189, 157, 112],
                    "effect": "solid"
                }
            })

            update_specific_light(luzes, [
                "light.living_fireplace_spot",
                "light.living_entry_door_light",
                "light.shoes_light",
                "light.entrance_dining_light",
                "light.corredor_door_light"
            ], {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 20,
                    "color_temp": 404
                }
            })

            update_specific_light(luzes, "light.chaise_light", {
                "action": "turn_off"
            })

            update_specific_light(luzes, "light.kitchen_led", {
                "action": "turn_on",
                "data": {
                    "rgbw_color": [230, 170, 30, 150],
                    "brightness_pct": 26,
                    "effect": "solid",
                    "transition": 2
                }
            })

            if("light.tv_shelf_group" in luzes):
                luzes = process_lights_shelfs(luzes)

    if scene == "bright":
        if hyperion_running == "off":
            update_specific_light(luzes, "light.tv_light", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 75,
                    "color_temp": 295
                }
            })
            update_specific_light(luzes, "light.tv_shelf_group", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 100,
                    "rgbw_color": [200, 130, 30, 200],
                    "effect": "solid"
                }
            })
            
            if("light.tv_shelf_group" in luzes):
                luzes = process_lights_shelfs(luzes)
        else:
            update_specific_light(luzes, "light.tv_light", {
                "action": "turn_off"
            })
            update_specific_light(luzes, "light.tv_shelf_group", {
                "action": "turn_off"
            })

        update_specific_light(luzes, "light.living_temperature_lights", {
            "action": "turn_on",
            "data": {
                "brightness_pct": 60,
                "color_temp": 367
            }
        })

        update_specific_light(luzes, "light.color_lights_without_tv_light", {
            "action": "turn_on",
            "data": {
                "brightness_pct": 75,
                "color_temp": 295
            }
        })

        update_specific_light(luzes, "light.window_led_strip", {
            "action": "turn_on",
            "data": {
                "brightness_pct": 100,
                "effect": "solid"
            }
        })

        update_specific_light(luzes, "light.zigbee_hub_estante_lights", {
            "action": "turn_on",
            "data": {
                "brightness_pct": 75,
                "color_temp": 295
            }
        })

        update_specific_light(luzes, "light.kitchen_led", {
            "action": "turn_on",
            "data": {
                "rgbw_color": [230, 170, 30, 150],
                "brightness_pct": 100,
                "effect": "solid"
            }
        })

        

    if scene == "brightest":
        if hyperion_running == "off":
            update_specific_light(luzes, "light.tv_light", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 100,
                    "color_temp": 295
                }
            })
            update_specific_light(luzes, "light.tv_shelf_group", {
                "action": "turn_on",
                "data": {
                    "brightness_pct": 100,
                    "rgbw_color": [200, 150, 20, 255],
                    "effect": "solid"
                }
            })
        else:
            update_specific_light(luzes, "light.tv_light", {
                "action": "turn_off"
            })

            update_specific_light(luzes, "light.tv_shelf_group", {
                "action": "turn_off"
            })

        update_specific_light(luzes, "light.living_temperature_lights", {
            "action": "turn_on",
            "data": {
                "brightness_pct": 100,
                "color_temp": 367
            }
        })

        update_specific_light(luzes, "light.color_lights_without_tv_light", {
            "action": "turn_on",
            "data": {
                "brightness_pct": 100,
                "color_temp": 295
            }
        })

        update_specific_light(luzes, "light.window_led_strip", {
            "action": "turn_on",
            "data": {
                "brightness_pct": 100,
                "effect": "solid"
            }
        })

        update_specific_light(luzes, "light.zigbee_hub_estante_lights", {
            "action": "turn_on",
            "data": {
                "brightness_pct": 100,
                "color_temp": 295
            }
        })

        update_specific_light(luzes, "light.kitchen_led", {
            "action": "turn_on",
            "data": {
                "rgbw_color": [230, 170, 30, 150],
                "brightness_pct": 100,
                "effect": "solid"
            }
        })
else:
    del luzes["light.color_lights"]
    del luzes["light.living_temperature_lights"]
    del luzes["light.window_led_strip"]
    del luzes["light.kitchen_led"]

# Executa as atualizações das luzes

updated_entities = update_lights(luzes)


#Informações de execução
end_time = datetime.datetime.now().timestamp() * 1000
duration = end_time - start_time
output["incio"] = f"{start_time} ms"
output["fim"] = f"{end_time} ms"
output["duracao"] = f"{duration} ms"
output["skipped_entities"] = skipped_entities
output["updated_entities"] = updated_entities

