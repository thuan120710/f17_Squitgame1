<template>
  <section class="squit-ui" :class="phase">
    <div class="main-row">
      <div class="phase-section">
        <span class="phase-dot" />
        <span class="phase-name">{{ label }}</span>
      </div>

      <div class="timer">{{ formattedRemaining }}</div>
    </div>

    <div class="bar-shell">
      <div class="bar-fill" :style="{ width: `${phasePercent}%` }" />
    </div>

    <div class="hint-row">
      <kbd>/exit</kbd>
      <span>Thoat minigame</span>
    </div>
  </section>
</template>

<script>
import { computed } from 'vue'

export default {
  name: 'SquitGameUI',
  props: {
    phase: {
      type: String,
      required: true
    },
    label: {
      type: String,
      required: true
    },
    remainingSeconds: {
      type: Number,
      required: true
    },
    phasePercent: {
      type: Number,
      required: true
    }
  },
  setup(props) {
    const formattedRemaining = computed(() => {
      const total = Math.max(0, Math.floor(props.remainingSeconds || 0))
      const minutes = String(Math.floor(total / 60)).padStart(2, '0')
      const seconds = String(total % 60).padStart(2, '0')
      return `${minutes}:${seconds}`
    })

    return {
      formattedRemaining
    }
  }
}
</script>

<style scoped>
.squit-ui {
  width: min(390px, calc(100vw - 32px));
  padding: 9px 11px 10px;
  border: 1px solid rgba(255, 190, 45, 0.36);
  border-radius: 8px;
  background: linear-gradient(135deg, rgba(58, 57, 60, 0.78), rgba(45, 44, 47, 0.78));
  box-shadow: 0 14px 38px rgba(0, 0, 0, 0.25);
  /* backdrop-filter: blur(10px); */
}

.main-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 8px;
}

.phase-section {
  display: flex;
  align-items: center;
  min-width: 0;
  flex: 1;
  gap: 9px;
}

.phase-dot {
  width: 10px;
  height: 10px;
  flex: 0 0 auto;
  border-radius: 999px;
  background: #FFD700;
  box-shadow: 0 0 12px rgba(255, 215, 0, 0.58);
}

.phase-name {
  min-width: 0;
  overflow: hidden;
  color: #FFD700;
  font-size: 13px;
  font-weight: 800;
  letter-spacing: 0;
  text-overflow: ellipsis;
  text-transform: uppercase;
  text-shadow: 0 0 10px rgba(255, 215, 0, 0.34);
  white-space: nowrap;
}

.timer {
  color: #FFD700;
  font-size: 14px;
  font-weight: 800;
  font-variant-numeric: tabular-nums;
  padding-left: 10px;
  border-left: 1px solid rgba(255, 190, 45, 0.26);
  text-shadow: 0 0 10px rgba(255, 215, 0, 0.34);
}

.bar-shell {
  position: relative;
  height: 8px;
  overflow: hidden;
  border-radius: 999px;
  background: rgba(255, 190, 45, 0.14);
}

.bar-fill {
  height: 100%;
  border-radius: inherit;
  background: linear-gradient(90deg, #FFD700, #ffbe2d);
  transition: width 100ms linear;
}

.hint-row {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 7px;
  margin-top: 7px;
  color: rgba(255, 255, 255, 0.62);
  font-size: 11px;
  font-weight: 600;
}

kbd {
  min-width: 38px;
  padding: 2px 7px 3px;
  border: 1px solid rgba(255, 190, 45, 0.36);
  border-radius: 5px;
  background: rgba(255, 190, 45, 0.16);
  color: #FFD700;
  font-family: Arial, Helvetica, sans-serif;
  font-size: 10px;
  font-weight: 800;
  text-align: center;
}

.squit-ui.green {
  border-color: rgba(80, 255, 145, 0.34);
}

.squit-ui.green .phase-dot,
.squit-ui.green .bar-fill {
  background: linear-gradient(90deg, #50ff91, #2edc78);
}

.squit-ui.green .phase-dot {
  box-shadow: 0 0 12px rgba(80, 255, 145, 0.58);
}

.squit-ui.green .phase-name,
.squit-ui.green .timer {
  color: #50ff91;
  text-shadow: 0 0 10px rgba(80, 255, 145, 0.3);
}

.squit-ui.yellow {
  border-color: rgba(255, 190, 45, 0.5);
  box-shadow: 0 14px 38px rgba(255, 190, 45, 0.12);
}

.squit-ui.yellow .phase-dot,
.squit-ui.yellow .bar-fill {
  background: linear-gradient(90deg, #FFD700, #ffbe2d);
}

.squit-ui.yellow .phase-name,
.squit-ui.yellow .timer {
  color: #FFD700;
}

.squit-ui.red {
  border-color: rgba(255, 74, 92, 0.42);
  box-shadow: 0 14px 38px rgba(255, 74, 92, 0.12);
}

.squit-ui.red .phase-dot,
.squit-ui.red .bar-fill {
  background: #ff4a5c;
}

.squit-ui.red .phase-dot {
  box-shadow: 0 0 12px rgba(255, 74, 92, 0.55);
}
</style>
