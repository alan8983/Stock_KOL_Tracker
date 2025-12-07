// Stock KOL Tracker - 圖表功能模組

// 圖表配置
const chartConfig = {
    colors: {
        primary: '#2563eb',
        success: '#10b981',
        danger: '#ef4444',
        warning: '#f59e0b',
        neutral: '#6b7280',
        background: '#f8fafc',
        grid: '#e2e8f0'
    },
    fonts: {
        family: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        size: {
            small: '12px',
            medium: '14px',
            large: '16px'
        }
    }
};

// 繪製股票價格線圖
function drawStockPriceChart(canvas, data, options = {}) {
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    
    // 清除畫布
    ctx.clearRect(0, 0, width, height);
    
    if (!data || data.length === 0) {
        drawNoDataMessage(ctx, width, height);
        return;
    }
    
    // 計算數據範圍
    const prices = data.map(d => d.price || d);
    const min = Math.min(...prices);
    const max = Math.max(...prices);
    const range = max - min;
    
    // 繪製背景網格
    drawGrid(ctx, width, height, min, max);
    
    // 繪製價格線
    drawPriceLine(ctx, data, width, height, min, range, options);
    
    // 繪製標籤
    if (options.showLabels !== false) {
        drawChartLabels(ctx, width, height, min, max);
    }
}

// 繪製KOL立場分析圖
function drawKOLSentimentChart(canvas, data, options = {}) {
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    
    // 清除畫布
    ctx.clearRect(0, 0, width, height);
    
    if (!data || data.length === 0) {
        drawNoDataMessage(ctx, width, height);
        return;
    }
    
    // 繪製背景
    drawSentimentBackground(ctx, width, height);
    
    // 繪製立場標記
    drawSentimentMarkers(ctx, data, width, height, options);
    
    // 繪製價格線
    drawPriceLine(ctx, data, width, height, 
        Math.min(...data.map(d => d.price)), 
        Math.max(...data.map(d => d.price)) - Math.min(...data.map(d => d.price)), 
        { ...options, showSentiment: true }
    );
}

// 繪製準確率進度條
function drawAccuracyProgressBar(canvas, accuracy, options = {}) {
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    
    // 清除畫布
    ctx.clearRect(0, 0, width, height);
    
    // 繪製背景
    ctx.fillStyle = chartConfig.colors.background;
    ctx.fillRect(0, 0, width, height);
    
    // 繪製進度條背景
    ctx.fillStyle = chartConfig.colors.grid;
    ctx.fillRect(0, height/2 - 4, width, 8);
    
    // 繪製進度條
    const progressWidth = (accuracy / 100) * width;
    const gradient = ctx.createLinearGradient(0, 0, width, 0);
    gradient.addColorStop(0, chartConfig.colors.success);
    gradient.addColorStop(1, chartConfig.colors.primary);
    
    ctx.fillStyle = gradient;
    ctx.fillRect(0, height/2 - 4, progressWidth, 8);
    
    // 繪製文字
    ctx.fillStyle = chartConfig.colors.primary;
    ctx.font = `${chartConfig.fonts.size.medium} ${chartConfig.fonts.family}`;
    ctx.textAlign = 'center';
    ctx.fillText(`${accuracy}%`, width/2, height/2 + 5);
}

// 繪製情緒變化圖
function drawSentimentTimeline(canvas, data, options = {}) {
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    
    // 清除畫布
    ctx.clearRect(0, 0, width, height);
    
    if (!data || data.length === 0) {
        drawNoDataMessage(ctx, width, height);
        return;
    }
    
    // 繪製時間軸
    drawTimelineAxis(ctx, width, height, data);
    
    // 繪製情緒標記
    drawTimelineMarkers(ctx, data, width, height);
}

// 繪製投資組合分布圖
function drawPortfolioDistribution(canvas, data, options = {}) {
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    
    // 清除畫布
    ctx.clearRect(0, 0, width, height);
    
    if (!data || data.length === 0) {
        drawNoDataMessage(ctx, width, height);
        return;
    }
    
    // 計算總值
    const total = data.reduce((sum, item) => sum + item.value, 0);
    
    // 繪製圓餅圖
    drawPieChart(ctx, data, width, height, total);
    
    // 繪製圖例
    if (options.showLegend !== false) {
        drawPieChartLegend(ctx, data, width, height);
    }
}

// 輔助函數

// 繪製網格
function drawGrid(ctx, width, height, min, max) {
    const gridLines = 5;
    ctx.strokeStyle = chartConfig.colors.grid;
    ctx.lineWidth = 1;
    
    for (let i = 0; i <= gridLines; i++) {
        const y = (i / gridLines) * height;
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(width, y);
        ctx.stroke();
    }
}

// 繪製價格線
function drawPriceLine(ctx, data, width, height, min, range, options = {}) {
    ctx.strokeStyle = options.color || chartConfig.colors.primary;
    ctx.lineWidth = options.lineWidth || 2;
    ctx.beginPath();
    
    data.forEach((item, index) => {
        const price = item.price || item;
        const x = (index / (data.length - 1)) * width;
        const y = height - ((price - min) / range) * height;
        
        if (index === 0) {
            ctx.moveTo(x, y);
        } else {
            ctx.lineTo(x, y);
        }
        
        // 繪製立場標記
        if (options.showSentiment && item.sentiment) {
            drawSentimentPoint(ctx, x, y, item.sentiment);
        }
    });
    
    ctx.stroke();
}

// 繪製立場標記
function drawSentimentPoint(ctx, x, y, sentiment) {
    const colors = {
        'strong_bullish': chartConfig.colors.success,
        'bullish': chartConfig.colors.success,
        'neutral': chartConfig.colors.neutral,
        'bearish': chartConfig.colors.danger,
        'strong_bearish': chartConfig.colors.danger
    };
    
    const symbols = {
        'strong_bullish': '▲',
        'bullish': '△',
        'neutral': '●',
        'bearish': '▽',
        'strong_bearish': '▼'
    };
    
    ctx.fillStyle = colors[sentiment] || chartConfig.colors.neutral;
    ctx.font = '16px Arial';
    ctx.textAlign = 'center';
    ctx.fillText(symbols[sentiment] || '●', x, y - 10);
}

// 繪製情緒背景
function drawSentimentBackground(ctx, width, height) {
    const gradient = ctx.createLinearGradient(0, 0, 0, height);
    gradient.addColorStop(0, 'rgba(16, 185, 129, 0.1)');   // 看多區域
    gradient.addColorStop(0.5, 'rgba(107, 114, 128, 0.1)'); // 中性區域
    gradient.addColorStop(1, 'rgba(239, 68, 68, 0.1)');     // 看空區域
    
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);
}

// 繪製立場標記
function drawSentimentMarkers(ctx, data, width, height, options) {
    data.forEach((item, index) => {
        if (item.sentiment) {
            const x = (index / (data.length - 1)) * width;
            const y = height / 2;
            drawSentimentPoint(ctx, x, y, item.sentiment);
        }
    });
}

// 繪製時間軸
function drawTimelineAxis(ctx, width, height, data) {
    ctx.strokeStyle = chartConfig.colors.grid;
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(0, height / 2);
    ctx.lineTo(width, height / 2);
    ctx.stroke();
}

// 繪製時間軸標記
function drawTimelineMarkers(ctx, data, width, height) {
    data.forEach((item, index) => {
        const x = (index / (data.length - 1)) * width;
        const y = height / 2;
        
        // 繪製時間標記
        if (item.date) {
            ctx.fillStyle = chartConfig.colors.text;
            ctx.font = `${chartConfig.fonts.size.small} ${chartConfig.fonts.family}`;
            ctx.textAlign = 'center';
            ctx.fillText(formatDate(item.date), x, height - 5);
        }
        
        // 繪製情緒標記
        if (item.sentiment) {
            drawSentimentPoint(ctx, x, y, item.sentiment);
        }
    });
}

// 繪製圓餅圖
function drawPieChart(ctx, data, width, height, total) {
    const centerX = width / 2;
    const centerY = height / 2;
    const radius = Math.min(width, height) / 3;
    
    let currentAngle = 0;
    
    data.forEach((item, index) => {
        const sliceAngle = (item.value / total) * 2 * Math.PI;
        
        ctx.beginPath();
        ctx.moveTo(centerX, centerY);
        ctx.arc(centerX, centerY, radius, currentAngle, currentAngle + sliceAngle);
        ctx.closePath();
        
        ctx.fillStyle = getColorByIndex(index);
        ctx.fill();
        
        currentAngle += sliceAngle;
    });
}

// 繪製圓餅圖圖例
function drawPieChartLegend(ctx, data, width, height) {
    const legendX = width - 120;
    const legendY = 20;
    const itemHeight = 20;
    
    data.forEach((item, index) => {
        const y = legendY + index * itemHeight;
        
        // 繪製顏色方塊
        ctx.fillStyle = getColorByIndex(index);
        ctx.fillRect(legendX, y, 15, 15);
        
        // 繪製文字
        ctx.fillStyle = chartConfig.colors.text;
        ctx.font = `${chartConfig.fonts.size.small} ${chartConfig.fonts.family}`;
        ctx.textAlign = 'left';
        ctx.fillText(item.name, legendX + 20, y + 12);
    });
}

// 繪製無數據訊息
function drawNoDataMessage(ctx, width, height) {
    ctx.fillStyle = chartConfig.colors.text;
    ctx.font = `${chartConfig.fonts.size.medium} ${chartConfig.fonts.family}`;
    ctx.textAlign = 'center';
    ctx.fillText('暫無數據', width / 2, height / 2);
}

// 繪製圖表標籤
function drawChartLabels(ctx, width, height, min, max) {
    ctx.fillStyle = chartConfig.colors.text;
    ctx.font = `${chartConfig.fonts.size.small} ${chartConfig.fonts.family}`;
    ctx.textAlign = 'right';
    
    // Y軸標籤
    for (let i = 0; i <= 5; i++) {
        const y = (i / 5) * height;
        const value = max - (i / 5) * (max - min);
        ctx.fillText(value.toFixed(2), width - 5, y + 4);
    }
}

// 工具函數

// 根據索引獲取顏色
function getColorByIndex(index) {
    const colors = [
        chartConfig.colors.primary,
        chartConfig.colors.success,
        chartConfig.colors.warning,
        chartConfig.colors.danger,
        chartConfig.colors.neutral
    ];
    return colors[index % colors.length];
}

// 格式化日期
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('zh-TW', {
        month: 'short',
        day: 'numeric'
    });
}

// 格式化價格
function formatPrice(price) {
    return new Intl.NumberFormat('zh-TW', {
        style: 'currency',
        currency: 'TWD',
        minimumFractionDigits: 2
    }).format(price);
}

// 創建圖表實例
class StockChart {
    constructor(canvas, options = {}) {
        this.canvas = canvas;
        this.ctx = canvas.getContext('2d');
        this.options = { ...chartConfig, ...options };
        this.data = [];
    }
    
    setData(data) {
        this.data = data;
        this.render();
    }
    
    render() {
        drawStockPriceChart(this.canvas, this.data, this.options);
    }
    
    resize(width, height) {
        this.canvas.width = width;
        this.canvas.height = height;
        this.render();
    }
}

class SentimentChart {
    constructor(canvas, options = {}) {
        this.canvas = canvas;
        this.ctx = canvas.getContext('2d');
        this.options = { ...chartConfig, ...options };
        this.data = [];
    }
    
    setData(data) {
        this.data = data;
        this.render();
    }
    
    render() {
        drawKOLSentimentChart(this.canvas, this.data, this.options);
    }
    
    resize(width, height) {
        this.canvas.width = width;
        this.canvas.height = height;
        this.render();
    }
}

class ProgressBar {
    constructor(canvas, options = {}) {
        this.canvas = canvas;
        this.ctx = canvas.getContext('2d');
        this.options = { ...chartConfig, ...options };
        this.value = 0;
    }
    
    setValue(value) {
        this.value = Math.max(0, Math.min(100, value));
        this.render();
    }
    
    render() {
        drawAccuracyProgressBar(this.canvas, this.value, this.options);
    }
    
    resize(width, height) {
        this.canvas.width = width;
        this.canvas.height = height;
        this.render();
    }
}

// 導出函數和類
window.ChartUtils = {
    drawStockPriceChart,
    drawKOLSentimentChart,
    drawAccuracyProgressBar,
    drawSentimentTimeline,
    drawPortfolioDistribution,
    StockChart,
    SentimentChart,
    ProgressBar,
    formatDate,
    formatPrice
}; 