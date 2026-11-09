<script setup lang="ts">
import type { StrategyResult } from '@/types';

const botStore = useBotStore();

const strategies = ref<string[]>([]);
const selectedStrategy = ref('');
const strategyDetails = ref<StrategyResult>();
const loadingList = ref(false);
const loadingDetails = ref(false);
const errorMessage = ref('');
let strategyRequest = 0;

watch(
  () => botStore.selectedBot,
  async (botId) => {
    strategyRequest += 1;
    strategies.value = [];
    selectedStrategy.value = '';
    strategyDetails.value = undefined;
    loadingList.value = false;
    loadingDetails.value = false;
    errorMessage.value = '';

    if (!botId || !botStore.hasBots) {
      return;
    }

    loadingList.value = true;
    const activeBot = botStore.activeBot;
    try {
      const result = await activeBot.getStrategyList();
      if (botStore.selectedBot !== botId) {
        return;
      }

      strategies.value = result.strategies;
      if (result.strategies.length > 0) {
        await loadStrategy(result.strategies[0]!);
      }
    } catch {
      if (botStore.selectedBot === botId) {
        errorMessage.value = 'Die Strategien konnten nicht geladen werden.';
      }
    } finally {
      if (botStore.selectedBot === botId) {
        loadingList.value = false;
      }
    }
  },
  { immediate: true },
);

async function loadStrategy(strategyName: string) {
  const botId = botStore.selectedBot;
  if (!botId || !botStore.hasBots) {
    return;
  }

  selectedStrategy.value = strategyName;
  strategyDetails.value = undefined;
  errorMessage.value = '';
  loadingDetails.value = true;
  const requestId = ++strategyRequest;

  try {
    const result = await botStore.activeBot.getStrategy(strategyName);
    if (botStore.selectedBot === botId && requestId === strategyRequest) {
      strategyDetails.value = result;
    }
  } catch {
    if (botStore.selectedBot === botId && requestId === strategyRequest) {
      errorMessage.value = `Details für ${strategyName} konnten nicht geladen werden.`;
    }
  } finally {
    if (botStore.selectedBot === botId && requestId === strategyRequest) {
      loadingDetails.value = false;
    }
  }
}
</script>

<template>
  <main class="mx-auto max-w-6xl p-4">
    <h1 class="mb-2 text-3xl font-bold">Strategien</h1>
    <p class="mb-4 text-neutral-500">
      Strategiecode und Parameter dieser Freqtrade-Instanz ansehen. Diese Ansicht ist
      schreibgeschützt.
    </p>

    <UAlert v-if="errorMessage" color="error" variant="soft" :title="errorMessage" class="mb-4" />

    <UCard v-if="!botStore.hasBots">
      <p>Verbinde zuerst einen Freqtrade-Bot, um seine Strategien zu sehen.</p>
    </UCard>
    <UCard v-else-if="loadingList">
      <p>Lade Strategien …</p>
    </UCard>
    <UCard v-else-if="strategies.length === 0">
      <p>Die Instanz meldet keine verfügbaren Strategien.</p>
    </UCard>
    <div v-else class="grid gap-4 md:grid-cols-[16rem_1fr]">
      <UCard>
        <template #header><h2 class="font-semibold">Verfügbare Strategien</h2></template>
        <div class="flex flex-col gap-2">
          <UButton
            v-for="name in strategies"
            :key="name"
            :label="name"
            :variant="selectedStrategy === name ? 'solid' : 'outline'"
            color="neutral"
            block
            @click="loadStrategy(name)"
          />
        </div>
      </UCard>

      <UCard v-if="strategyDetails">
        <template #header>
          <div class="flex flex-wrap items-center justify-between gap-2">
            <h2 class="text-xl font-semibold">{{ strategyDetails.strategy }}</h2>
            <span class="text-sm text-neutral-500"
              >Zeitrahmen: {{ strategyDetails.timeframe }}</span
            >
          </div>
        </template>
        <StrategyParameters :strategy="strategyDetails" />
        <details v-if="strategyDetails.code" class="mt-4">
          <summary class="cursor-pointer font-medium">Strategiecode anzeigen</summary>
          <pre
            class="mt-2 max-h-[60vh] overflow-auto rounded bg-neutral-100 p-3 text-xs dark:bg-neutral-900"
          ><code>{{ strategyDetails.code }}</code></pre>
        </details>
      </UCard>
      <UCard v-else>
        <p v-if="loadingDetails">Lade Strategiedetails …</p>
        <p v-else>Wähle eine Strategie aus der Liste.</p>
      </UCard>
    </div>
  </main>
</template>
