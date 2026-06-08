<script setup lang="ts">
import { router } from '@inertiajs/vue3'

defineProps<{ count: number }>()
</script>

<template>
  <div style="display:flex; flex-direction:column; align-items:center; justify-content:center; height:100vh; gap:32px">
    <div style="font-size:96px; font-weight:700; line-height:1; font-variant-numeric:tabular-nums">
      {{ count }}
    </div>
    <div style="display:flex; gap:10px">
      <button class="btn btn-secondary" @click="router.post('/decrement')">−</button>
      <button class="btn btn-secondary" @click="router.post('/reset')">Reset</button>
      <button class="btn btn-primary" @click="router.post('/increment')">+</button>
    </div>
  </div>
</template>
