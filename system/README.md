# Dell Latitude 7400: temperatura, ruído do cooler e bateria (Omarchy)

> **Pacote `system` dos dotfiles.** Esses arquivos ficam **fora do `$HOME`**
> (`/etc`, `/usr/local/bin`), então **não** são instalados pelo `stow`. Eles
> são copiados para o sistema pelo script:
>
> ```bash
> cd ~/.dotfiles/system
> sudo ./install-system.sh
> ```
>
> O script instala o `intel-undervolt` se faltar, copia
> `etc/intel-undervolt.conf`, `etc/systemd/system/power-limits.service` e
> `usr/local/bin/set-power-limits`, ativa os serviços, aplica tudo na hora e
> configura o limite de carga da bateria (75% → 80%). Só roda num Latitude
> 7400: o undervolt é calibrado para esse processador. Em outra máquina, só
> com `FORCE=1`.
>
> **Ao mudar alguma configuração no sistema, copie de volta para cá** (ex.:
> `cp /etc/intel-undervolt.conf ~/.dotfiles/system/etc/`) e faça commit.

Ajustes feitos em **2026-10-14** para o notebook esquentar menos e o cooler
fazer menos barulho no uso do dia a dia.

| Item | Valor |
|---|---|
| Máquina | Dell Latitude 7400 (hostname `dell7400`) |
| CPU | Intel Core i7-8665U (8ª geração, Whiskey Lake), 4 núcleos / 8 threads, TDP nominal 15 W |
| GPU | Intel UHD 620 |
| Sistema | Omarchy (Arch) |
| BIOS | 1.43.0 (2025-09-08) |

---

## 1. Diagnóstico

- **Em repouso a temperatura era normal**: ~50 °C, cooler parado. O
  aquecimento aparecia em carga, principalmente com o Chromium.
- **O undervolt já estava funcionando** (−80 mV), mas reduz só alguns watts.
- **Causa principal:** o firmware da Dell deixava o processador rodar
  **22 W de forma contínua** (PL1) e picos de **51 W** (PL2). O valor nominal
  desse chip é **15 W**. Num gabinete fino de 14", 22 W contínuos geram muito
  calor e fazem o cooler acelerar o tempo todo.
- O perfil "balanced" com EPP `balance_performance` faz o processador usar o
  turbo com agressividade em qualquer carga pequena.

---

## 2. O que foi alterado

### 2.1 Undervolt: −80 mV → −90 mV (permanente)

Ferramenta: `intel-undervolt`, configurada em `/etc/intel-undervolt.conf` e
aplicada no boot por `intel-undervolt.service`.

| Plano de tensão | Antes | Agora |
|---|---|---|
| CPU | −80 mV | **−90 mV** |
| CPU Cache | −80 mV | **−90 mV** |
| GPU | −60 mV | −60 mV (sem mudança) |
| System Agent / Analog I/O | 0 | 0 |

CPU e CPU Cache precisam ter o **mesmo valor**: nesse processador eles
compartilham a mesma tensão.

Configuração anterior salva em `/etc/intel-undervolt.conf.bak-pre-90mv`.

### 2.2 Limites de potência: 22 W / 51 W → 15 W / 30 W (permanente)

| Limite | Padrão da Dell | Agora |
|---|---|---|
| PL1 (contínuo) | 22 W | **15 W** (TDP nominal do chip) |
| PL2 (picos curtos) | 51 W | **30 W** |

Arquivos criados:

- **`/usr/local/bin/set-power-limits`**: script que grava os limites no Intel RAPL:
  ```bash
  R=/sys/class/powercap/intel-rapl:0
  echo 15000000 > $R/constraint_0_power_limit_uw   # PL1: 15 W
  echo 30000000 > $R/constraint_1_power_limit_uw   # PL2: 30 W
  ```
- **`/etc/systemd/system/power-limits.service`**: serviço oneshot que roda o
  script **no boot e toda vez que o notebook volta da suspensão ou
  hibernação**, porque o firmware pode restaurar os limites padrão ao acordar:
  ```ini
  [Unit]
  Description=CPU power limits 15 W / 30 W (Intel RAPL)
  After=multi-user.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target

  [Service]
  Type=oneshot
  ExecStart=/usr/local/bin/set-power-limits

  [Install]
  WantedBy=multi-user.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target
  ```

No uso comum (navegador, terminal, editor de código) a perda de desempenho
é quase imperceptível.

### 2.3 Perfil de energia (escolha manual, no menu do Omarchy)

O `power-profiles-daemon` controla o perfil térmico da Dell
(`/sys/firmware/acpi/platform_profile`). Opções disponíveis: `cool`,
`quiet`, `balanced`, `performance`.

| No menu do Omarchy | Perfil Dell | Quando usar |
|---|---|---|
| **Power saver** | `quiet` | Mais silencioso e frio. Bom para reuniões e uso leve. |
| **Balanced** | `balanced` | Uso normal do dia a dia (o atual). |
| **Performance** | `performance` | Só para tarefas pesadas, e por pouco tempo: o cooler prioriza velocidade e a CPU usa o turbo ao máximo. |

Trocar o perfil **não** altera o undervolt nem os limites de 15 W / 30 W.

---

### 2.4 Limite de carga da bateria: 80–90% → 75–80% (permanente)

A bateria (DELL N2K62, 60 Wh de fábrica) está com **~67% de saúde** (~40 Wh).
O que mais a desgasta é ficar muito tempo perto de 100% na tomada. Como o
notebook fica ligado na tomada a maior parte do tempo, o limite foi
apertado:

| | Antes | Agora |
|---|---|---|
| Modo (`charge_types`) | Custom | Custom |
| Começa a carregar abaixo de | 80% | **75%** |
| Para de carregar em | 90% | **80%** |
| Bateria disponível fora da tomada | ~36 Wh | ~32 Wh |

- Os limites ficam gravados **na BIOS**: valem depois de reiniciar e até
  com o notebook desligado. Não precisa de serviço.
- A Dell exige pelo menos **5 pontos** de diferença entre início e fim.
- Com a bateria entre 75% e 80% na tomada, o status mostra
  "Not charging". É normal: é o limite funcionando.

Comando usado:
```bash
echo 75 | sudo tee /sys/class/power_supply/BAT0/charge_control_start_threshold
echo 80 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold
```

**Viagem ou dia longe da tomada** (carregar até 100% só naquele dia):
```bash
echo Standard | sudo tee /sys/class/power_supply/BAT0/charge_types   # carrega até 100%
echo Custom   | sudo tee /sys/class/power_supply/BAT0/charge_types   # volta para 75–80%
```

Outras faixas, conforme o uso:

| Uso | Faixa |
|---|---|
| Na tomada quase sempre | 50% → 60% (máxima longevidade, ~24 Wh fora da tomada) |
| **Na tomada a maior parte do tempo (atual)** | **75% → 80%** |
| Fora da tomada com frequência | 80% → 90% |

Outros modos da Dell: `Standard` (até 100%), `Adaptive` (a BIOS ajusta
pelo padrão de uso), `Fast` (carga rápida, desgasta mais), `Trickle`
(carga lenta, para quem fica sempre na tomada).

---

## 3. Resultado medido

| Situação | Temperatura |
|---|---|
| Perfil `quiet` + limites novos (repouso) | 46 °C, cooler parado |
| Perfil `performance` (logo após trocar) | 71 °C |
| Perfil `balanced` + limites novos | 57 °C, cooler parado |

---

## 4. Como verificar

```bash
# Perfil atual e limites de potência
powerprofilesctl get
cat /sys/firmware/acpi/platform_profile
R=/sys/class/powercap/intel-rapl:0
echo "PL1=$(( $(cat $R/constraint_0_power_limit_uw)/1000000 ))W PL2=$(( $(cat $R/constraint_1_power_limit_uw)/1000000 ))W"

# Undervolt aplicado (precisa de root)
sudo intel-undervolt read

# Serviço dos limites
systemctl status power-limits.service

# Temperatura e cooler
sensors | grep -E "Package|fan1"

# Limite de carga da bateria
B=/sys/class/power_supply/BAT0
echo "modo: $(cat $B/charge_types) | início: $(cat $B/charge_control_start_threshold)% | fim: $(cat $B/charge_control_end_threshold)% | agora: $(cat $B/capacity)% ($(cat $B/status))"
```

Esperado: `PL1=15W PL2=30W`, CPU e CPU Cache em cerca de −89,84 mV, bateria em `[Custom]` com início 75% e fim 80%.

---

## 5. Como desfazer

**Voltar o undervolt para −80 mV** (se aparecerem travamentos, reinícios
sozinhos ou programas fechando em carga, que são sinais de undervolt
instável):
```bash
sudo cp /etc/intel-undervolt.conf.bak-pre-90mv /etc/intel-undervolt.conf
sudo intel-undervolt apply
```

**Remover os limites de potência** (volta a 22 W / 51 W no próximo boot):
```bash
sudo systemctl disable --now power-limits.service
# opcional, apagar os arquivos:
sudo rm /etc/systemd/system/power-limits.service /usr/local/bin/set-power-limits
sudo systemctl daemon-reload
```

**Voltar o limite de carga para 80–90%** (o fim primeiro, para manter
os 5 pontos de diferença):
```bash
echo 90 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold
echo 80 | sudo tee /sys/class/power_supply/BAT0/charge_control_start_threshold
```

**Mudar os valores dos limites:** editar `/usr/local/bin/set-power-limits`
(valores em microwatts: 15 W = `15000000`) e rodar
`sudo systemctl restart power-limits.service`.

---

## 6. Próximos passos, se ainda esquentar

1. **Limpeza e troca da pasta térmica.** O notebook é de 2019 (a bateria
   está com ~67% da capacidade original, sinal da idade). Pasta térmica
   ressecada e poeira no cooler e no dissipador costumam somar **10 a 15 °C**
   em carga, e nenhum ajuste de software resolve isso. É o ganho mais
   provável depois destes ajustes.
2. **Vídeo pela GPU no Chromium.** Conferir em `chrome://gpu` se
   "Video Decode" está acelerado por hardware. Isso tira muita carga da CPU
   em YouTube e Meet.
3. **Bateria.** O modelo é DELL N2K62 (60 Wh de fábrica, hoje ~40 Wh).
   Trocar devolve a autonomia original.
