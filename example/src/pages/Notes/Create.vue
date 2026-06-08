<script setup lang="ts">
import { router } from '@inertiajs/vue3'
import { ref } from 'vue'

const props = defineProps<{
  errors?: Record<string, string>
  values?: { title?: string; content?: string }
}>()

const form = ref({ title: props.values?.title ?? '', content: props.values?.content ?? '' })
</script>

<template>
  <div class="shell">
    <div class="page-header">
      <button class="btn btn-secondary btn-sm" @click="router.get('/notes')">← Back</button>
      <span style="font-weight:600">New Note</span>
      <div style="width:52px" />
    </div>
    <form
      class="content"
      style="padding:16px; gap:14px; display:flex; flex-direction:column; overflow-y:auto"
      @submit.prevent="router.post('/notes', form)"
    >
      <div class="field">
        <label>Title</label>
        <input type="text" v-model="form.title" placeholder="Note title" />
        <span v-if="errors?.title" class="text-xs text-muted" style="color:#ef4444">{{ errors.title }}</span>
      </div>
      <div class="field" style="flex:1">
        <label>Content</label>
        <textarea v-model="form.content" placeholder="Write something…" style="flex:1; resize:none; min-height:120px" />
      </div>
      <button type="submit" class="btn btn-primary">Save</button>
    </form>
  </div>
</template>
