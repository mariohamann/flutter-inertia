<script setup lang="ts">
import { router } from '@inertiajs/vue3'

defineProps<{ notes: { id: string; title: string; content: string }[] }>()
</script>

<template>
  <div class="shell">
    <div class="page-header">
      <button class="btn btn-secondary btn-sm" @click="router.get('/')">← Back</button>
      <span style="font-weight:600">Notes</span>
      <button class="btn btn-primary btn-sm" @click="router.get('/notes/create')">New</button>
    </div>
    <div class="content" style="overflow-y:auto; padding:12px; gap:8px; display:flex; flex-direction:column">
      <p v-if="notes.length === 0" class="text-muted text-sm" style="text-align:center; padding:32px 0">No notes yet</p>
      <div
        v-for="note in notes"
        :key="note.id"
        class="card"
        style="padding:12px 14px; display:flex; align-items:center; gap:10px; cursor:pointer"
        @click="router.get(`/notes/${note.id}`)"
      >
        <div style="flex:1; min-width:0">
          <div class="text-truncate" style="font-weight:500">{{ note.title }}</div>
          <div v-if="note.content" class="text-xs text-muted text-truncate">{{ note.content }}</div>
        </div>
        <button
          class="btn btn-secondary btn-sm"
          @click.stop="router.get(`/notes/${note.id}/edit`)"
        >Edit</button>
        <button
          class="btn btn-danger btn-sm"
          @click.stop="router.delete(`/notes/${note.id}`)"
        >Delete</button>
      </div>
    </div>
  </div>
</template>
