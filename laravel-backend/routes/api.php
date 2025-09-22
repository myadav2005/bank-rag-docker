<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\RagController;

Route::middleware('auth:sanctum')->post('/ask', [RagController::class, 'ask']);
