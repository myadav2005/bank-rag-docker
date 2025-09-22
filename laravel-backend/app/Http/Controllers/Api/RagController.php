<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class RagController extends Controller
{
    public function ask(Request $request)
    {
        $query = $request->input('query');

        if (!$query) {
            return response()->json(['error' => 'Query is required'], 400);
        }

        // Call Python service for embedding
        $embeddingResponse = Http::post('http://python-flask:5001/embed', [
            'text' => $query
        ]);

        if (!$embeddingResponse->ok()) {
            return response()->json(['error' => 'Embedding service failed'], 500);
        }

        $embedding = $embeddingResponse->json()['embedding'];

        // Simple DB retrieval (example: last 5 transactions)
        $transactions = DB::table('transactions')
            ->orderBy('date', 'desc')
            ->limit(5)
            ->get();

        // Call LLaMA model
        $llmResponse = Http::post('http://llama:11434/api/generate', [
            'model' => 'llama2',
            'prompt' => "Answer the question: {$query}\nUse these transactions as context: " . json_encode($transactions)
        ]);

        if (!$llmResponse->ok()) {
            return response()->json(['error' => 'LLM service failed'], 500);
        }

        return response()->json([
            'answer' => $llmResponse->json()['response']
        ]);
    }
}
