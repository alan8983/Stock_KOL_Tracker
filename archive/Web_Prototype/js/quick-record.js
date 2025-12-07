// 快速記錄頁面功能

let selectedFiles = [];
let analysisInProgress = false;

// 頁面初始化
document.addEventListener('DOMContentLoaded', function() {
    setupFileUpload();
    setupDragAndDrop();
    setupFormValidation();
});

// 設置文件上傳
function setupFileUpload() {
    const fileInput = document.getElementById('image-upload');
    fileInput.addEventListener('change', handleFileSelect);
}

// 設置拖拽上傳
function setupDragAndDrop() {
    const uploadArea = document.getElementById('upload-area');
    
    uploadArea.addEventListener('dragover', function(e) {
        e.preventDefault();
        uploadArea.classList.add('drag-over');
    });
    
    uploadArea.addEventListener('dragleave', function(e) {
        e.preventDefault();
        uploadArea.classList.remove('drag-over');
    });
    
    uploadArea.addEventListener('drop', function(e) {
        e.preventDefault();
        uploadArea.classList.remove('drag-over');
        
        const files = Array.from(e.dataTransfer.files);
        handleFiles(files);
    });
}

// 設置表單驗證
function setupFormValidation() {
    const contentInput = document.getElementById('kol-content');
    const analyzeBtn = document.getElementById('analyze-btn');
    
    function validateForm() {
        const hasContent = contentInput.value.trim().length > 0;
        const hasFiles = selectedFiles.length > 0;
        
        analyzeBtn.disabled = !(hasContent || hasFiles);
        analyzeBtn.classList.toggle('disabled', !(hasContent || hasFiles));
    }
    
    contentInput.addEventListener('input', validateForm);
    validateForm();
}

// 處理文件選擇
function handleFileSelect(event) {
    const files = Array.from(event.target.files);
    handleFiles(files);
}

// 處理文件
function handleFiles(files) {
    const validFiles = files.filter(file => {
        const isValidType = ['image/jpeg', 'image/png', 'image/gif'].includes(file.type);
        const isValidSize = file.size <= 10 * 1024 * 1024; // 10MB限制
        
        if (!isValidType) {
            showNotification('只支援 JPG、PNG、GIF 格式的圖片', 'warning');
        }
        
        if (!isValidSize) {
            showNotification('圖片大小不能超過 10MB', 'warning');
        }
        
        return isValidType && isValidSize;
    });
    
    selectedFiles = [...selectedFiles, ...validFiles];
    updateFilePreview();
    setupFormValidation();
}

// 更新文件預覽
function updateFilePreview() {
    const previewContainer = document.getElementById('image-preview');
    const previewList = document.getElementById('preview-list');
    
    if (selectedFiles.length === 0) {
        previewContainer.style.display = 'none';
        return;
    }
    
    previewContainer.style.display = 'block';
    previewList.innerHTML = '';
    
    selectedFiles.forEach((file, index) => {
        const previewItem = document.createElement('div');
        previewItem.className = 'preview-item';
        
        const reader = new FileReader();
        reader.onload = function(e) {
            previewItem.innerHTML = `
                <div class="preview-image">
                    <img src="${e.target.result}" alt="預覽圖片">
                </div>
                <div class="preview-info">
                    <div class="file-name">${file.name}</div>
                    <div class="file-size">${formatFileSize(file.size)}</div>
                </div>
                <button class="remove-file" onclick="removeFile(${index})">
                    <i class="fas fa-times"></i>
                </button>
            `;
        };
        reader.readAsDataURL(file);
        
        previewList.appendChild(previewItem);
    });
}

// 移除文件
function removeFile(index) {
    selectedFiles.splice(index, 1);
    updateFilePreview();
    setupFormValidation();
}

// 重設表單
function resetForm() {
    const contentInput = document.getElementById('kol-content');
    const previewContainer = document.getElementById('image-preview');
    const progressSection = document.getElementById('analysis-progress');
    
    contentInput.value = '';
    selectedFiles = [];
    previewContainer.style.display = 'none';
    progressSection.style.display = 'none';
    
    // 重置進度
    resetProgress();
    
    // 重新啟用分析按鈕
    const analyzeBtn = document.getElementById('analyze-btn');
    analyzeBtn.disabled = true;
    analyzeBtn.classList.add('disabled');
    
    showNotification('表單已重設', 'info');
}

// 開始分析
function startAnalysis() {
    if (analysisInProgress) {
        return;
    }
    
    const content = document.getElementById('kol-content').value.trim();
    const hasContent = content.length > 0;
    const hasFiles = selectedFiles.length > 0;
    
    if (!hasContent && !hasFiles) {
        showNotification('請輸入內容或上傳圖片', 'warning');
        return;
    }
    
    analysisInProgress = true;
    showAnalysisProgress();
    
    // 模擬AI分析過程
    simulateAnalysis(content, selectedFiles);
}

// 顯示分析進度
function showAnalysisProgress() {
    const progressSection = document.getElementById('analysis-progress');
    const inputSection = document.querySelector('.input-section');
    
    progressSection.style.display = 'block';
    inputSection.style.display = 'none';
    
    // 禁用分析按鈕
    const analyzeBtn = document.getElementById('analyze-btn');
    analyzeBtn.disabled = true;
    analyzeBtn.classList.add('disabled');
}

// 模擬AI分析
function simulateAnalysis(content, files) {
    const steps = [
        { id: 'step-1', name: '識別投資標的', duration: 2000 },
        { id: 'step-2', name: '分析投資敘事', duration: 2500 },
        { id: 'step-3', name: '提取時間資訊', duration: 1500 },
        { id: 'step-4', name: '情緒分析', duration: 2000 }
    ];
    
    let currentStep = 0;
    const totalDuration = steps.reduce((sum, step) => sum + step.duration, 0);
    let elapsed = 0;
    
    function updateProgress() {
        if (currentStep >= steps.length) {
            completeAnalysis();
            return;
        }
        
        const step = steps[currentStep];
        const stepEl = document.getElementById(step.id);
        const progressFill = document.getElementById('progress-fill');
        
        // 激活當前步驟
        stepEl.classList.add('active');
        
        // 更新進度條
        elapsed += 100;
        const progress = Math.min((elapsed / totalDuration) * 100, 100);
        progressFill.style.width = `${progress}%`;
        
        // 檢查是否完成當前步驟
        if (elapsed >= steps.slice(0, currentStep + 1).reduce((sum, s) => sum + s.duration, 0)) {
            stepEl.classList.add('completed');
            currentStep++;
        }
        
        setTimeout(updateProgress, 100);
    }
    
    updateProgress();
}

// 完成分析
function completeAnalysis() {
    setTimeout(() => {
        // 創建模擬分析結果
        const analysisResult = {
            stock: 'AAPL',
            stockName: '蘋果公司',
            narrative: '看好蘋果公司在AI領域的創新能力，認為其產品生態系統具有長期競爭優勢。',
            timestamp: new Date().toISOString(),
            sentiment: 'strong_bullish',
            confidence: 0.85
        };
        
        // 保存分析結果到本地存儲
        localStorage.setItem('lastAnalysisResult', JSON.stringify(analysisResult));
        
        // 跳轉到記錄摘要頁面
        window.location.href = 'record-summary.html';
    }, 1000);
}

// 重置進度
function resetProgress() {
    const steps = ['step-1', 'step-2', 'step-3', 'step-4'];
    steps.forEach(stepId => {
        const stepEl = document.getElementById(stepId);
        stepEl.classList.remove('active', 'completed');
    });
    
    const progressFill = document.getElementById('progress-fill');
    progressFill.style.width = '0%';
    
    analysisInProgress = false;
}

// 返回上一頁
function goBack() {
    if (analysisInProgress) {
        if (confirm('分析正在進行中，確定要離開嗎？')) {
            resetProgress();
            window.history.back();
        }
    } else {
        window.history.back();
    }
}

// 工具函數

// 格式化文件大小
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// 模擬OCR處理
function processImageOCR(file) {
    return new Promise((resolve) => {
        // 模擬OCR處理時間
        setTimeout(() => {
            // 模擬OCR結果
            const mockOCRResult = `圖片識別結果：
            
這是一張關於蘋果公司(AAPL)的投資分析截圖。
KOL表示看好蘋果在AI領域的發展前景，
認為iPhone 15的銷量表現優於預期，
建議投資者可以考慮逢低買入。`;
            
            resolve(mockOCRResult);
        }, 2000);
    });
}

// 模擬AI文本分析
function analyzeText(text) {
    return new Promise((resolve) => {
        setTimeout(() => {
            const result = {
                stock: 'AAPL',
                stockName: '蘋果公司',
                narrative: '看好蘋果公司在AI領域的創新能力，認為其產品生態系統具有長期競爭優勢。',
                timestamp: new Date().toISOString(),
                sentiment: 'strong_bullish',
                confidence: 0.85
            };
            
            resolve(result);
        }, 1500);
    });
}

// 導出函數
window.QuickRecord = {
    startAnalysis,
    resetForm,
    removeFile,
    goBack
}; 