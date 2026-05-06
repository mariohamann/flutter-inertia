<script setup lang="ts">
import { router } from '@inertiajs/vue3'
import { reactive } from 'vue'

const form = reactive({ title: '', body: '' })

function submit() {
  router.post('/notes', { ...form })
}
</script>

<template>
  <div style="max-width:600px;margin:2rem auto;padding:0 1rem">
    <h1 style="font-size:1.5rem;margin-bottom:1rem">New Note</h1>

    <form @submit.prevent="submit" style="display:flex;flex-direction:column;gap:1rem">
      <label>
        <span style="display:block;margin-bottom:.25rem;font-size:.875rem;font-weight:500">Title</span>
        <input v-model="form.title" required
               style="width:100%;padding:.5rem .75rem;border:1px solid #d1d5db;border-radius:6px;font-size:1rem" />
      </label>

      <label>
        <span style="display:block;margin-bottom:.25rem;font-size:.875rem;font-weight:500">Body</span>
        <textarea v-model="form.body" rows="5"
                  style="width:100%;padding:.5rem .75rem;border:1px solid #d1d5db;border-radius:6px;font-size:1rem;resize:vertical"></textarea>
      </label>

      <div style="display:flex;gap:.75rem">
        <button type="submit"
                style="padding:.5rem 1.25rem;background:#2563eb;color:#fff;border:none;border-radius:6px;cursor:pointer;font-size:1rem">
          Save
        </button>
        <button type="button"
                @click="router.get('/')"
                style="padding:.5rem 1.25rem;background:#e5e7eb;border:none;border-radius:6px;cursor:pointer;font-size:1rem">
          Cancel
        </button>
      </div>
    </form>
  </div>
</template>
