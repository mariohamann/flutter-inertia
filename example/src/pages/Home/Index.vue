<script setup lang="ts">
import { router } from '@inertiajs/vue3'
</script>

<template>
  <div style="display:flex; flex-direction:column; align-items:center; justify-content:center; height:100vh; gap:16px; padding:24px">
    <h1 style="font-size:28px; font-weight:700; margin-bottom:8px">Examples</h1>
    <button class="btn btn-secondary" style="width:200px" @click="router.get('/counter')">My Counter</button>
    <button class="btn btn-secondary" style="width:200px" @click="router.get('/notes')">My Notes</button>
    <button class="btn btn-secondary" style="width:200px" @click="router.get('/notification')">My Notification</button>
  </div>
</template>
