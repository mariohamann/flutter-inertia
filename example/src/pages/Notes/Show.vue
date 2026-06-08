<script setup lang="ts">
import { router } from '@inertiajs/vue3'

defineProps<{ note: { id: string; title: string; content: string } }>()
</script>

<template>
  <div class="shell">
    <div class="page-header">
      <button class="btn btn-secondary btn-sm" @click="router.get('/notes')">← Back</button>
      <span style="font-weight:600; flex:1; text-align:center" class="text-truncate">{{ note.title }}</span>
      <button class="btn btn-secondary btn-sm" @click="router.get(`/notes/${note.id}/edit`)">Edit</button>
    </div>
    <div class="content" style="padding:16px; overflow-y:auto">
      <p v-if="note.content" style="white-space:pre-wrap; line-height:1.6">{{ note.content }}</p>
      <p v-else class="text-muted text-sm">No content</p>
    </div>
  </div>
</template>
