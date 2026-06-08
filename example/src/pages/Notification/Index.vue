<script setup lang="ts">
import { router } from '@inertiajs/vue3'
import { ref } from 'vue'

defineProps<{ error?: string; sent?: boolean }>()

const text = ref('')
</script>

<template>
  <div class="shell">
    <div class="page-header">
      <button class="btn btn-secondary btn-sm" @click="router.get('/')">← Back</button>
      <span style="font-weight:600">Notification</span>
      <div style="width:52px" />
    </div>
    <form
      class="content"
      style="padding:16px; gap:14px; display:flex; flex-direction:column"
      @submit.prevent="router.post('/notification', { text })"
    >
      <div class="field">
        <label>Message</label>
        <input type="text" v-model="text" placeholder="Enter notification text…" />
        <span v-if="error" class="text-xs" style="color:#ef4444">{{ error }}</span>
      </div>
      <button type="submit" class="btn btn-primary">Send Notification</button>
      <p v-if="sent" class="text-sm text-muted" style="text-align:center">Notification sent!</p>
    </form>
  </div>
</template>
