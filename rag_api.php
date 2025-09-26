<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
    exit();
}

$input = json_decode(file_get_contents('php://input'), true);
$query = $input['query'] ?? '';

if (empty($query)) {
    http_response_code(400);
    echo json_encode(['error' => 'Query is required']);
    exit();
}

try {
    // Step 1: Get embedding from Python service
    $embeddingData = [
        'text' => $query
    ];
    
    $embeddingContext = stream_context_create([
        'http' => [
            'method' => 'POST',
            'header' => 'Content-Type: application/json',
            'content' => json_encode($embeddingData)
        ]
    ]);
    
    $embeddingResponse = file_get_contents('http://python-flask:5001/embed', false, $embeddingContext);
    
    if ($embeddingResponse === false) {
        throw new Exception('Embedding service failed');
    }
    
    $embedding = json_decode($embeddingResponse, true)['embedding'];
    
    // Step 2: Simulate vector search (using sample data for demo)
    $sampleTransactions = [
        ['amount' => 2500, 'type' => 'deposit', 'date' => '2025-09-25', 'description' => 'Salary deposit'],
        ['amount' => -150, 'type' => 'withdrawal', 'date' => '2025-09-24', 'description' => 'ATM withdrawal'],
        ['amount' => -75, 'type' => 'withdrawal', 'date' => '2025-09-23', 'description' => 'Grocery store']
    ];
    
    // Step 3: Generate response using LLM
    $llmData = [
        'model' => 'llama3.2:1b',
        'prompt' => "You are a helpful bank assistant. Answer this customer question: {$query}\n\nContext from recent transactions: " . json_encode($sampleTransactions) . "\n\nProvide a helpful, accurate response.",
        'stream' => false
    ];
    
    $llmContext = stream_context_create([
        'http' => [
            'method' => 'POST',
            'header' => 'Content-Type: application/json',
            'content' => json_encode($llmData)
        ]
    ]);
    
    $llmResponse = file_get_contents('http://llama:11434/api/generate', false, $llmContext);
    
    if ($llmResponse === false) {
        throw new Exception('LLM service failed');
    }
    
    $llmResult = json_decode($llmResponse, true);
    
    // Return successful RAG response
    echo json_encode([
        'success' => true,
        'query' => $query,
        'answer' => $llmResult['response'],
        'embedding_dimensions' => count($embedding),
        'context_transactions' => count($sampleTransactions),
        'rag_status' => 'operational'
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'error' => 'RAG processing failed: ' . $e->getMessage()
    ]);
}
?>