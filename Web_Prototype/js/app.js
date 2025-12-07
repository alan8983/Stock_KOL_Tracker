// Stock KOL Tracker - 主要應用邏輯

// 全局變數
let currentUser = null;
let stockData = [];
let kolData = [];
let investmentData = [];

// 初始化應用
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
    setupEventListeners();
    loadMockData();
    updateUI();
});

// 初始化應用
function initializeApp() {
    console.log('Stock KOL Tracker 初始化中...');
    
    // 檢查本地存儲
    const savedUser = localStorage.getItem('stockKOLUser');
    if (savedUser) {
        currentUser = JSON.parse(savedUser);
    } else {
        // 創建默認用戶
        currentUser = {
            id: 'user_' + Date.now(),
            nickname: '瞎忙散戶',
            experience: '1-3年',
            riskTolerance: '中高',
            monthlyInvestment: '5萬',
            createdAt: new Date().toISOString()
        };
        localStorage.setItem('stockKOLUser', JSON.stringify(currentUser));
    }
    
    // 載入數據
    loadStockData();
    loadKOLData();
    loadInvestmentData();
}

// 設置事件監聽器
function setupEventListeners() {
    // 底部導航
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => {
        item.addEventListener('click', function(e) {
            e.preventDefault();
            const href = this.getAttribute('href');
            navigateToPage(href);
        });
    });
    
    // 股票卡片點擊
    const stockCards = document.querySelectorAll('.stock-card');
    stockCards.forEach(card => {
        card.addEventListener('click', function() {
            const symbol = this.querySelector('.stock-symbol').textContent;
            navigateToStockDetail(symbol);
        });
    });
}

// 載入模擬數據
function loadMockData() {
    // 模擬股票數據
    stockData = [
        {
            symbol: 'AAPL',
            name: '蘋果公司',
            price: 195.20,
            change: 2.5,
            changePercent: 2.5,
            volume: '45.2M',
            marketCap: '3.1T',
            chartData: [180, 182, 185, 188, 195]
        },
        {
            symbol: 'TSLA',
            name: '特斯拉',
            price: 245.80,
            change: -3.0,
            changePercent: -1.2,
            volume: '32.1M',
            marketCap: '780B',
            chartData: [248, 246, 244, 247, 246]
        },
        {
            symbol: 'MSFT',
            name: '微軟',
            price: 415.50,
            change: 3.3,
            changePercent: 0.8,
            volume: '28.7M',
            marketCap: '3.1T',
            chartData: [412, 413, 414, 415, 416]
        },
        {
            symbol: 'NVDA',
            name: '輝達',
            price: 890.20,
            change: 26.8,
            changePercent: 3.1,
            volume: '52.3M',
            marketCap: '2.2T',
            chartData: [863, 870, 875, 885, 890]
        }
    ];
    
    // 模擬KOL數據
    kolData = [
        {
            id: 'kol_1',
            name: '財經達人A',
            accuracy: 75,
            avgReturn: 8.5,
            totalPosts: 156,
            followers: 1234,
            expertise: ['科技股', 'AI概念股'],
            posts: [
                {
                    id: 'post_1',
                    stock: 'AAPL',
                    content: '看好蘋果公司在AI領域的創新能力',
                    sentiment: 'strong_bullish',
                    timestamp: '2025-07-15T14:30:00Z',
                    accuracy: true
                }
            ]
        },
        {
            id: 'kol_2',
            name: '投資專家B',
            accuracy: 68,
            avgReturn: 6.2,
            totalPosts: 89,
            followers: 856,
            expertise: ['價值投資', '藍籌股'],
            posts: []
        },
        {
            id: 'kol_3',
            name: '分析師C',
            accuracy: 82,
            avgReturn: 12.1,
            totalPosts: 234,
            followers: 2156,
            expertise: ['技術分析', '短線交易'],
            posts: []
        }
    ];
    
    // 模擬投資數據
    investmentData = [
        {
            id: 'inv_1',
            stock: 'AAPL',
            buyPrice: 185.50,
            currentPrice: 195.20,
            quantity: 54,
            buyDate: '2025-07-12T10:30:00Z',
            status: 'holding',
            kolFollowers: ['kol_1', 'kol_2'],
            totalPosts: 5,
            latestNarrative: 'AI創新能力看好',
            notes: ''
        },
        {
            id: 'inv_2',
            stock: 'TSLA',
            buyPrice: 248.80,
            currentPrice: 245.80,
            quantity: 40,
            buyDate: '2025-07-08T14:15:00Z',
            status: 'holding',
            kolFollowers: ['kol_3'],
            totalPosts: 3,
            latestNarrative: '電動車市場競爭加劇',
            notes: ''
        },
        {
            id: 'inv_3',
            stock: 'NVDA',
            buyPrice: 820.00,
            currentPrice: 890.20,
            quantity: 12,
            buyDate: '2025-06-30T09:45:00Z',
            status: 'sold',
            sellPrice: 890.20,
            sellDate: '2025-07-14T16:20:00Z',
            kolFollowers: ['kol_1', 'kol_3'],
            totalPosts: 8,
            latestNarrative: 'AI晶片需求強勁',
            notes: '獲利了結，等待回調'
        }
    ];
    
    // 保存到本地存儲
    localStorage.setItem('stockData', JSON.stringify(stockData));
    localStorage.setItem('kolData', JSON.stringify(kolData));
    localStorage.setItem('investmentData', JSON.stringify(investmentData));
}

// 載入股票數據
function loadStockData() {
    const saved = localStorage.getItem('stockData');
    if (saved) {
        stockData = JSON.parse(saved);
    }
}

// 載入KOL數據
function loadKOLData() {
    const saved = localStorage.getItem('kolData');
    if (saved) {
        kolData = JSON.parse(saved);
    }
}

// 載入投資數據
function loadInvestmentData() {
    const saved = localStorage.getItem('investmentData');
    if (saved) {
        investmentData = JSON.parse(saved);
    }
}

// 更新UI
function updateUI() {
    updateStockCards();
    updateNavigation();
    drawMiniCharts();
}

// 更新股票卡片
function updateStockCards() {
    const stockCards = document.querySelectorAll('.stock-card');
    stockCards.forEach((card, index) => {
        if (stockData[index]) {
            const stock = stockData[index];
            const symbolEl = card.querySelector('.stock-symbol');
            const nameEl = card.querySelector('.stock-name');
            const changeEl = card.querySelector('.change-value');
            const iconEl = card.querySelector('.stock-change i');
            
            if (symbolEl) symbolEl.textContent = stock.symbol;
            if (nameEl) nameEl.textContent = stock.name;
            if (changeEl) {
                changeEl.textContent = `${stock.changePercent > 0 ? '+' : ''}${stock.changePercent}%`;
                changeEl.className = `change-value ${stock.changePercent > 0 ? 'positive' : 'negative'}`;
            }
            if (iconEl) {
                iconEl.className = `fas fa-arrow-${stock.changePercent > 0 ? 'up' : 'down'}`;
            }
            
            // 更新卡片狀態
            card.className = `stock-card ${stock.changePercent > 0 ? 'positive' : 'negative'}`;
        }
    });
}

// 更新導航
function updateNavigation() {
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    const navItems = document.querySelectorAll('.nav-item');
    
    navItems.forEach(item => {
        const href = item.getAttribute('href');
        if (href === currentPage) {
            item.classList.add('active');
        } else {
            item.classList.remove('active');
        }
    });
}

// 繪製迷你圖表
function drawMiniCharts() {
    const charts = document.querySelectorAll('.mini-chart');
    charts.forEach((canvas, index) => {
        if (stockData[index]) {
            drawStockChart(canvas, stockData[index].chartData);
        }
    });
}

// 繪製股票圖表
function drawStockChart(canvas, data) {
    const ctx = canvas.getContext('2d');
    const width = canvas.width;
    const height = canvas.height;
    
    // 清除畫布
    ctx.clearRect(0, 0, width, height);
    
    // 計算數據範圍
    const min = Math.min(...data);
    const max = Math.max(...data);
    const range = max - min;
    
    // 繪製線條
    ctx.strokeStyle = '#10b981';
    ctx.lineWidth = 2;
    ctx.beginPath();
    
    data.forEach((value, index) => {
        const x = (index / (data.length - 1)) * width;
        const y = height - ((value - min) / range) * height;
        
        if (index === 0) {
            ctx.moveTo(x, y);
        } else {
            ctx.lineTo(x, y);
        }
    });
    
    ctx.stroke();
}

// 導航功能
function navigateToPage(page) {
    window.location.href = page;
}

function navigateToQuickRecord() {
    navigateToPage('quick-record.html');
}

function navigateToKOLAnalysis() {
    navigateToPage('kol-analysis.html');
}

function navigateToJournal() {
    navigateToPage('investment-journal.html');
}

function navigateToStockDetail(symbol) {
    navigateToPage(`stock-detail.html?symbol=${symbol}`);
}

// 數據管理功能
function saveData() {
    localStorage.setItem('stockData', JSON.stringify(stockData));
    localStorage.setItem('kolData', JSON.stringify(kolData));
    localStorage.setItem('investmentData', JSON.stringify(investmentData));
}

function addInvestment(investment) {
    investment.id = 'inv_' + Date.now();
    investment.createdAt = new Date().toISOString();
    investmentData.push(investment);
    saveData();
    updateUI();
}

function updateInvestment(id, updates) {
    const index = investmentData.findIndex(inv => inv.id === id);
    if (index !== -1) {
        investmentData[index] = { ...investmentData[index], ...updates };
        saveData();
        updateUI();
    }
}

function deleteInvestment(id) {
    investmentData = investmentData.filter(inv => inv.id !== id);
    saveData();
    updateUI();
}

// 工具函數
function formatCurrency(amount) {
    return new Intl.NumberFormat('zh-TW', {
        style: 'currency',
        currency: 'TWD'
    }).format(amount);
}

function formatPercentage(value) {
    return `${value > 0 ? '+' : ''}${value.toFixed(2)}%`;
}

function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString('zh-TW');
}

function formatDateTime(dateString) {
    return new Date(dateString).toLocaleString('zh-TW');
}

// 驗證函數
function validateStockSymbol(symbol) {
    return /^[A-Z]{1,5}$/.test(symbol);
}

function validatePrice(price) {
    return !isNaN(price) && price > 0;
}

// 通知功能
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.classList.add('show');
    }, 100);
    
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 300);
    }, 3000);
}

// 載入動畫
function showLoading(element) {
    element.innerHTML = '<div class="loading"></div>';
}

function hideLoading(element, content) {
    element.innerHTML = content;
}

// 錯誤處理
function handleError(error, context = '') {
    console.error(`Error in ${context}:`, error);
    showNotification(`發生錯誤: ${error.message}`, 'error');
}

// 導出函數供其他模組使用
window.StockKOLTracker = {
    navigateToQuickRecord,
    navigateToKOLAnalysis,
    navigateToJournal,
    navigateToStockDetail,
    addInvestment,
    updateInvestment,
    deleteInvestment,
    showNotification,
    formatCurrency,
    formatPercentage,
    formatDate,
    formatDateTime,
    validateStockSymbol,
    validatePrice,
    stockData,
    kolData,
    investmentData,
    currentUser
}; 