<script setup lang="ts">
import { router } from '@inertiajs/vue3'

defineProps<{ count: number }>()
</script>

<template>
  <div class="shell">
    <div class="page-header">
      <button class="btn btn-secondary btn-sm" @click="router.get('/')">← Back</button>
      <span style="font-weight:600">Counter</span>
      <div style="width:52px" />
    </div>
    <div class="content" style="align-items:center; justify-content:center">
      <div style="font-size:96px; font-weight:700; line-height:1; font-variant-numeric:tabular-nums">
        {{ count }}
      </div>
      <div style="display:flex; gap:10px; margin-top:32px">
        <button class="btn btn-secondary" @click="router.post('/decrement')">−</button>
        <button class="btn btn-secondary" @click="router.post('/reset')">Reset</button>
        <button class="btn btn-primary" @click="router.post('/increment')">+</button>
      </div>
    </div>
  </div>
</template>
