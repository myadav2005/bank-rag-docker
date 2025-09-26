<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Response;
use App\Http\Controllers\Api\RagController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// Health check endpoint
Route::get('/health', function () {
    return Response::json([
        'status' => 'ok',
        'timestamp' => now()->toISOString(),
        'services' => [
            'laravel' => 'running',
            'database' => 'configured',
            'python_embedding' => 'available',
            'ollama_llm' => 'available'
        ]
    ]);
});

// Test endpoints (no auth required)
Route::prefix('test')->group(function () {
    Route::get('/ping', function () {
        return Response::json(['message' => 'pong']);
    });
    
    Route::get('/python', function () {
        try {
            $response = \Illuminate\Support\Facades\Http::timeout(5)
                ->post('http://localhost:5001/embed', ['text' => 'test']);
            return Response::json([
                'python_service' => 'ok',
                'response' => $response->json()
            ]);
        } catch (\Exception $e) {
            return Response::json([
                'python_service' => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    });
    
    Route::get('/ollama', function () {
        try {
            $response = \Illuminate\Support\Facades\Http::timeout(10)
                ->get('http://localhost:11434/api/version');
            return Response::json([
                'ollama_service' => 'ok',
                'response' => $response->json()
            ]);
        } catch (\Exception $e) {
            return Response::json([
                'ollama_service' => 'error',
                'message' => $e->getMessage()
            ], 500);
        }
    });
});

// Test RAG endpoint (no auth for testing) - temporarily disabled
// Route::post('/test/ask', [RagController::class, 'ask']);

// Protected RAG endpoint - temporarily disabled  
// Route::middleware('auth:sanctum')->post('/ask', [RagController::class, 'ask']);
