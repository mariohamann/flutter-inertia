<script setup lang="ts">
import { router } from '@inertiajs/vue3'
import { ref } from 'vue'

defineProps<{
  notes: { id: string; title: string; body: string }[]
}>()

const confirmDeleteId = ref<string | null>(null)

function deleteNote(id: string) {
  router.delete(`/notes/${id}`)
}
</script>

<template>
  <div style="max-width:600px;margin:2rem auto;padding:0 1rem">
    <h1 style="font-size:1.5rem;margin-bottom:1rem">Notes</h1>

    <!-- Inline confirm banner -->
    <div v-if="confirmDeleteId !== null"
         style="position:fixed;inset:0;background:rgba(0,0,0,.4);display:flex;align-items:center;justify-content:center;z-index:100">
      <div style="background:#fff;border-radius:10px;padding:1.5rem;max-width:300px;text-align:center">
        <p style="margin-bottom:1rem;font-size:1rem">Delete this note?</p>
        <div style="display:flex;gap:.75rem;justify-content:center">
          <button @click="deleteNote(confirmDeleteId!); confirmDeleteId = null"
                  style="padding:.5rem 1.25rem;background:#dc2626;color:#fff;border:none;border-radius:6px;cursor:pointer">
            Delete
          </button>
          <button @click="confirmDeleteId = null"
                  style="padding:.5rem 1.25rem;background:#e5e7eb;border:none;border-radius:6px;cursor:pointer">
            Cancel
          </button>
        </div>
      </div>
    </div>

    <a href="/notes/create"
       @click.prevent="router.get('/notes/create')"
       style="display:inline-block;margin-bottom:1.5rem;padding:.5rem 1rem;background:#2563eb;color:#fff;border-radius:6px;text-decoration:none">
      + New note
    </a>

    <p v-if="notes.length === 0" style="color:#888">No notes yet. Create one!</p>

    <ul style="list-style:none;display:flex;flex-direction:column;gap:.75rem">
      <li v-for="note in notes" :key="note.id"
          style="background:#fff;border-radius:8px;padding:1rem;box-shadow:0 1px 3px rgba(0,0,0,.1)">
        <strong style="font-size:1rem">{{ note.title }}</strong>
        <p style="margin:.25rem 0 .75rem;color:#555;font-size:.9rem">{{ note.body }}</p>
        <div style="display:flex;gap:.5rem">
          <button
            @click="router.get(`/notes/${note.id}/edit`)"
            style="padding:.35rem .75rem;background:#e5e7eb;border:none;border-radius:4px;cursor:pointer">
            Edit
          </button>
          <button
            @click="confirmDeleteId = note.id"
            style="padding:.35rem .75rem;background:#fee2e2;border:none;border-radius:4px;cursor:pointer;color:#991b1b">
            Delete
          </button>
        </div>
      </li>
    </ul>
  </div>
</template>
