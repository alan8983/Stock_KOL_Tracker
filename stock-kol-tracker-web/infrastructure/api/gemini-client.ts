import { GoogleGenerativeAI } from '@google/generative-ai';

export interface AnalysisResult {
  sentiment: 'Bullish' | 'Bearish' | 'Neutral';
  kolName?: string;
  postedAtText?: string;
  tickers?: string[];
  tickerAnalyses?: Array<{
    ticker: string;
    sentiment: 'Bullish' | 'Bearish' | 'Neutral';
    isPrimary: boolean;
  }>;
  narrative?: string;
  confidence?: number;
  analysis?: Record<string, unknown>;
}

export class GeminiClient {
  private genAI: GoogleGenerativeAI;
  private model: any;

  constructor(apiKey: string) {
    this.genAI = new GoogleGenerativeAI(apiKey);
    this.model = this.genAI.getGenerativeModel({
      model: 'gemini-2.5-flash',
      generationConfig: {
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      },
    });
  }

  async analyzeText(text: string): Promise<AnalysisResult> {
    if (text.trim().isEmpty) {
      return this.emptyResult();
    }

    try {
      const prompt = this.buildPrompt(text);
      const result = await this.model.generateContent(prompt);
      const response = await result.response;
      const responseText = response.text();

      if (!responseText || responseText.trim().isEmpty) {
        return this.emptyResult();
      }

      // 提取 JSON
      const jsonString = this.extractJson(responseText);
      const jsonData = this.parseJson(jsonString);

      return this.parseAnalysisResult(jsonData);
    } catch (error: any) {
      console.error('Gemini API 錯誤:', error);
      throw new Error(`AI 分析失敗: ${error.message || '未知錯誤'}`);
    }
  }

  private buildPrompt(text: string): string {
    return `你是一個專業的美股金融分析助手。請分析以下 KOL 的投資觀點文字。

任務：
1. **多標的分析**：為每個提及的美股代號獨立判斷情緒
   - 提取所有提及的美股代號 (1-5個大寫字母，如 AAPL、TSLA)
   - 為每個股票代號判斷情緒：Bullish（看漲）、Bearish（看跌）、Neutral（中性）
   - 標記主要標的（isPrimary: true）和次要標的（isPrimary: false）

2. **KOL 識別**：從文字中提取 KOL 名稱
   - 如果文字是 KOL 的發言，提取 KOL 名稱
   - 如果無法識別，kolName 設為 null

3. **時間識別**：從文字中提取發文時間
   - 支援相對時間（如「3小時前」、「昨天」）
   - 支援絕對時間（如「12月11日下午2:02」）
   - 如果無法識別，postedAtText 設為 null

4. **整體情緒判斷**：根據主要標的的情緒判斷整體情緒
   - 如果有多個標的，以主要標的的情緒為準
   - 如果沒有主要標的，以第一個標的情緒為準

請以 JSON 格式回應，格式如下：
\`\`\`json
{
  "sentiment": "Bullish" | "Bearish" | "Neutral",
  "kolName": "KOL名稱或null",
  "postedAtText": "時間文字或null",
  "tickerAnalyses": [
    {
      "ticker": "AAPL",
      "sentiment": "Bullish",
      "isPrimary": true
    }
  ],
  "narrative": "市場敘事（選填）",
  "confidence": 0.85
}
\`\`\`

待分析文字：
${text}`;
  }

  private extractJson(text: string): string {
    // 移除 markdown 程式碼區塊標記
    let jsonString = text.replace(/```json\n?/g, '').replace(/```\n?/g, '').trim();

    // 尋找 JSON 物件
    const jsonMatch = jsonString.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      jsonString = jsonMatch[0];
    }

    return jsonString;
  }

  private parseJson(jsonString: string): any {
    try {
      return JSON.parse(jsonString);
    } catch (error) {
      // 嘗試修復不完整的 JSON
      const repaired = this.repairIncompleteJson(jsonString);
      if (repaired) {
        try {
          return JSON.parse(repaired);
        } catch (e) {
          throw new Error('JSON 解析失敗');
        }
      }
      throw new Error('JSON 解析失敗');
    }
  }

  private repairIncompleteJson(jsonString: string): string | null {
    // 簡單的 JSON 修復：補全缺失的結束括號
    let repaired = jsonString.trim();
    const openBraces = (repaired.match(/\{/g) || []).length;
    const closeBraces = (repaired.match(/\}/g) || []).length;

    if (openBraces > closeBraces) {
      repaired += '}'.repeat(openBraces - closeBraces);
      return repaired;
    }

    return null;
  }

  private parseAnalysisResult(jsonData: any): AnalysisResult {
    // 處理多標的分析結果
    const tickerAnalyses = jsonData.tickerAnalyses || [];
    const tickers = tickerAnalyses.map((t: any) => t.ticker);

    // 如果沒有 tickerAnalyses，使用舊的 tickers 格式
    if (tickerAnalyses.length === 0 && jsonData.tickers) {
      tickers.push(...jsonData.tickers);
    }

    // 判斷整體情緒（以主要標的為準）
    let sentiment: 'Bullish' | 'Bearish' | 'Neutral' = 'Neutral';
    if (tickerAnalyses.length > 0) {
      const primaryTicker = tickerAnalyses.find((t: any) => t.isPrimary);
      if (primaryTicker) {
        sentiment = primaryTicker.sentiment;
      } else {
        sentiment = tickerAnalyses[0].sentiment;
      }
    } else if (jsonData.sentiment) {
      sentiment = jsonData.sentiment;
    }

    return {
      sentiment,
      kolName: jsonData.kolName || undefined,
      postedAtText: jsonData.postedAtText || undefined,
      tickers: tickers.length > 0 ? tickers : undefined,
      tickerAnalyses: tickerAnalyses.length > 0 ? tickerAnalyses : undefined,
      narrative: jsonData.narrative || undefined,
      confidence: jsonData.confidence || undefined,
      analysis: jsonData,
    };
  }

  private emptyResult(): AnalysisResult {
    return {
      sentiment: 'Neutral',
    };
  }
}
