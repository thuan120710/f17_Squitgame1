<template>
  <div class="squit-container" :class="{ red: phase === 'red' }">
    <div class="red-vignette" />

    <transition name="countdown-fade">
      <div v-if="showCountdown" class="countdown-overlay">
        <div class="countdown-number">{{ countdownNumber }}</div>
        <div class="countdown-text">SAN SANG</div>
      </div>
    </transition>

    <transition name="slide-fade">
      <SquitGameUI
        v-show="isVisible"
        :phase="phase"
        :label="phaseLabel"
        :remaining-seconds="remainingSeconds"
        :phase-percent="phasePercent"
      />
    </transition>
  </div>
</template>

<script>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import SquitGameUI from './components/SquitGameUI.vue'

export default {
  name: 'App',
  components: {
    SquitGameUI
  },
  setup() {
    const isVisible = ref(false)
    const showCountdown = ref(false)
    const countdownNumber = ref(5)
    const phase = ref('green')
    const remainingSeconds = ref(240)
    const phaseDuration = ref(1)
    const phaseRemaining = ref(1)
    const resultLabel = ref('')
    const phaseSeq = ref(0)

    const phaseLabels = {
      green: 'CHAY',
      yellow: 'CHUAN BI DUNG',
      red: 'DUNG'
    }

    const phaseLabel = computed(() => resultLabel.value || phaseLabels[phase.value] || phaseLabels.green)
    const phasePercent = computed(() => {
      const percent = (phaseRemaining.value / Math.max(1, phaseDuration.value)) * 100
      return Math.max(0, Math.min(100, percent))
    })

    const playSound = (soundFile, volume = 0.5) => {
      const audio = new Audio(`./sounds/${soundFile}.mp3`)
      audio.volume = volume
      audio.play().catch(() => {})
    }

    const applyCountdown = (seconds) => {
      countdownNumber.value = seconds || 5
      showCountdown.value = true
    }

    const applyClientState = (data, force = false) => {
      const incomingSeq = Number(data.seq || 0)
      if (!force && incomingSeq > 0 && incomingSeq < phaseSeq.value) {
        return
      }

      phaseSeq.value = Math.max(phaseSeq.value, incomingSeq)
      phase.value = data.phase || phase.value || 'green'
      phaseDuration.value = Math.max(1, Number(data.phaseDuration ?? phaseDuration.value) || 1)
      phaseRemaining.value = Math.max(0, Number(data.phaseRemaining ?? phaseRemaining.value) || 0)
      remainingSeconds.value = Math.max(0, Number(data.remaining ?? remainingSeconds.value) || 0)
      resultLabel.value = ''
    }

    const handleMessage = (event) => {
      const data = event.data
      if (!data) return

      if (data.transactionType === 'playSound') {
        playSound(data.transactionFile, data.transactionVolume || 0.5)
        return
      }

      if (data.action === 'countdown') {
        applyCountdown(data.seconds || 5)
        return
      }

      if (data.action === 'countdownHide') {
        showCountdown.value = false
        return
      }

      if (data.action === 'show') {
        isVisible.value = true
        phaseSeq.value = 0
        applyClientState(data, true)
        return
      }

      if (data.action === 'hide') {
        isVisible.value = false
        showCountdown.value = false
        resultLabel.value = ''
        return
      }

      if (data.action === 'state') {
        applyClientState(data)
        return
      }

      if (data.action === 'result') {
        resultLabel.value = data.result === 'win' ? 'VE DICH' : 'BI LOAI'
        phaseRemaining.value = phaseDuration.value
      }
    }

    onMounted(() => {
      window.addEventListener('message', handleMessage)
    })

    onBeforeUnmount(() => {
      window.removeEventListener('message', handleMessage)
    })

    return {
      isVisible,
      showCountdown,
      countdownNumber,
      phase,
      phaseLabel,
      remainingSeconds,
      phasePercent,
      resultLabel
    }
  }
}
</script>

<style scoped>
.squit-container {
  position: relative;
  width: 100%;
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: flex-start;
  padding-top: 3vh;
}

.red-vignette {
  position: fixed;
  inset: 0;
  opacity: 0;
  border: 4px solid rgba(255, 47, 67, 0);
  box-shadow: inset 0 0 58px rgba(255, 47, 67, 0);
  transition: opacity 180ms ease, border-color 180ms ease, box-shadow 180ms ease;
}

.squit-container.red .red-vignette {
  opacity: 1;
  border-color: rgba(255, 47, 67, 0.2);
  box-shadow: inset 0 0 42px rgba(255, 47, 67, 0.14);
}

.countdown-overlay {
  position: fixed;
  top: 50%;
  left: 50%;
  z-index: 20;
  text-align: center;
  transform: translate(-50%, -50%);
}

.countdown-number {
  color: #FFD700;
  font-size: clamp(82px, 13vw, 168px);
  font-weight: 900;
  line-height: 0.9;
  text-shadow: 0 0 20px rgba(255, 215, 0, 0.62), 0 12px 34px rgba(0, 0, 0, 0.48);
}

.countdown-text {
  margin-top: 14px;
  color: rgba(255, 255, 255, 0.78);
  font-size: 17px;
  font-weight: 800;
}

.countdown-fade-enter-active,
.countdown-fade-leave-active {
  transition: opacity 0.35s ease;
}

.countdown-fade-enter-from,
.countdown-fade-leave-to {
  opacity: 0;
}

.slide-fade-enter-active {
  transition: all 0.35s ease-out;
}

.slide-fade-leave-active {
  transition: all 0.22s ease-in;
}

.slide-fade-enter-from {
  opacity: 0;
  transform: translateY(-18px);
}

.slide-fade-leave-to {
  opacity: 0;
  transform: translateY(-12px);
}

</style>
