<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Response;

class RagController extends Controller
{
    public function ask(Request $request)
    {
        $query = $request->input('query');

        if (!$query) {
            return Response::json(['error' => 'Query is required'], 400);
        }

        // Call Python service for embedding
        $embeddingResponse = Http::post('http://python-flask:5001/embed', [
            'text' => $query
        ]);

        if (!$embeddingResponse->ok()) {
            return Response::json(['error' => 'Embedding service failed'], 500);
        }

        $embedding = $embeddingResponse->json()['embedding'];

        // Simple DB retrieval (example: last 5 transactions)
        $transactions = DB::table('transactions')
            ->orderBy('date', 'desc')
            ->limit(5)
            ->get();

        // Call LLaMA model
        $llmResponse = Http::post('http://llama:11434/api/generate', [
            'model' => 'llama3.2:1b',
            'prompt' => "Answer the question: {$query}\nUse these transactions as context: " . json_encode($transactions),
            'stream' => false
        ]);

        if (!$llmResponse->ok()) {
            return Response::json(['error' => 'LLM service failed'], 500);
        }

        return Response::json([
            'answer' => $llmResponse->json()['response']
        ]);
    }
}
