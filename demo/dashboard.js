    let priceChart = null;
    let currentLang = 'en';

    const translations = {
      en: {
        heroTitle: "Real-Time Farmer Intelligence & Mandi Forecast",
        heroSubtitle: "Multi-modal fusion of Sentinel-2 satellite STAC, IMD gridded weather, & AgMarkNet mandi prices",
        yieldTitle: "Yield Forecast",
        priceTitle: "14-Day Mandi Price Prediction",
        pestTitle: "Pest & Disease Outbreak Surveillance",
        satelliteTitle: "Sentinel-2 & Soil Health Card Fusion",
        runBtn: "⚡ Run Advisory",
        currPrice: "Current Spot Price:",
        projPrice: "14-Day Forecast:"
      },
      hi: {
        heroTitle: "किसान एआई सलाहकार एवं मंडी मूल्य पूर्वानुमान",
        heroSubtitle: "सेंटिनल-2 उपग्रह, मौसम विभाग (IMD) और एगमार्कनेट मंडी डेटा का बहुआयामी विश्लेषण",
        yieldTitle: "उपज पूर्वानुमान",
        priceTitle: "14-दिवसीय मंडी भाव पूर्वानुमान",
        pestTitle: "कीट एवं रोग प्रकोप निगरानी",
        satelliteTitle: "उपग्रह एवं मृदा स्वास्थ्य कार्ड संलयन",
        runBtn: "⚡ सलाह प्राप्त करें",
        currPrice: "वर्तमान मंडी भाव:",
        projPrice: "14-दिन का अनुमान:"
      },
      mr: {
        heroTitle: "शेतकरी एआय सल्लागार आणि बाजारभाव अंदाज",
        heroSubtitle: "सेंटिनेल-२ उपग्रह, हवामान विभाग आणि ॲगमार्कनेट बाजारभाव आकडेवारीचे एकत्रीकरण",
        yieldTitle: "उत्पादन अंदाज",
        priceTitle: "१४-दिवसीय बाजारभाव अंदाज",
        pestTitle: "कीड व रोग प्रादुर्भाव इशारा",
        satelliteTitle: "उपग्रह व मृदा आरोग्य पत्रिका विश्लेषण",
        runBtn: "⚡ सल्ला मिळवा",
        currPrice: "आजचा बाजारभाव:",
        projPrice: "१४ दिवसांचा अंदाज:"
      }
    };

    const CROP_DATA = {
      cotton: {
        yieldKg: 1820,
        unit: 'kg / hectare',
        confidence: '89.4%',
        ndvi: '0.68',
        rain: '842 mm',
        soil: '7.2 pH',
        spotPrice: 7150,
        forecastPrice: 7480,
        change: '+4.6%',
        prices: [7100, 7120, 7150, 7190, 7230, 7280, 7310, 7350, 7390, 7420, 7450, 7460, 7475, 7480],
        adv: "Optimal harvest moisture. Recommendation: HOLD harvest by 7 days for peak mandi price realization.",
        advHi: "मिट्टी में नमी अनुकूल है। अधिकतम मंडी भाव प्राप्त करने के लिए फसल को 7 दिन रोककर बेचें।",
        advMr: "जमिनीतील ओलावा योग्य आहे. जास्तीत जास्त बाजारभाव मिळवण्यासाठी शेतमाल ७ दिवस राखून ठेवा."
      },
      soybean: {
        yieldKg: 2150,
        unit: 'kg / hectare',
        confidence: '92.1%',
        ndvi: '0.74',
        rain: '910 mm',
        soil: '6.8 pH',
        spotPrice: 4650,
        forecastPrice: 4890,
        change: '+5.2%',
        prices: [4620, 4640, 4650, 4680, 4710, 4750, 4780, 4810, 4830, 4850, 4870, 4880, 4890, 4890],
        adv: "Strong export demand and MSP support. Sell 50% lot at ₹4,850+ target.",
        advHi: "मजबूत निर्यात मांग और एमएसपी समर्थन। ₹4,850+ के लक्ष्य पर 50% उपज बेचें।",
        advMr: "चांगली निर्यात मागणी आणि हमीभाव आधार. ₹४,८५०+ भावावर ५०% माल विका."
      },
      wheat: {
        yieldKg: 3450,
        unit: 'kg / hectare',
        confidence: '94.0%',
        ndvi: '0.81',
        rain: '320 mm',
        soil: '7.5 pH',
        spotPrice: 2420,
        forecastPrice: 2490,
        change: '+2.9%',
        prices: [2400, 2410, 2420, 2430, 2445, 2450, 2460, 2470, 2475, 2480, 2485, 2490, 2490, 2490],
        adv: "Stable domestic procurement. Normal seasonal mandi trends.",
        advHi: "स्थिर सरकारी खरीद और सामान्य मौसमी मंडी रुझान।",
        advMr: "स्थिर शासकीय खरेदी आणि सर्वसाधारण बाजार कल."
      },
      tur: {
        yieldKg: 1120,
        unit: 'kg / hectare',
        confidence: '86.5%',
        ndvi: '0.62',
        rain: '780 mm',
        soil: '7.0 pH',
        spotPrice: 10400,
        forecastPrice: 10950,
        change: '+5.3%',
        prices: [10200, 10300, 10400, 10450, 10550, 10620, 10700, 10780, 10840, 10890, 10910, 10930, 10940, 10950],
        adv: "Tight pulse supply buffer. High probability of crossing ₹11,000 threshold.",
        advHi: "दालों की तंग आपूर्ति। ₹11,000 की सीमा पार करने की उच्च संभावना।",
        advMr: "डाळींचा तुटवडा. ₹११,००० चा टप्पा ओलांडण्याची दाट शक्यता."
      }
    };

    function initChart() {
      if (typeof Chart === 'undefined') {
        const message = document.createElement('p');
        message.textContent = 'Chart could not load. The sample prices remain available below.';
        document.getElementById('priceChart').replaceWith(message);
        return;
      }
      const ctx = document.getElementById('priceChart').getContext('2d');
      const labels = Array.from({length: 14}, (_, i) => `Day +${i + 1}`);

      const gradient = ctx.createLinearGradient(0, 0, 0, 250);
      gradient.addColorStop(0, 'rgba(16, 185, 129, 0.35)');
      gradient.addColorStop(1, 'rgba(16, 185, 129, 0.0)');

      priceChart = new Chart(ctx, {
        type: 'line',
        data: {
          labels: labels,
          datasets: [{
            label: 'Sample mandi price scenario (₹/Qtl)',
            data: CROP_DATA.cotton.prices,
            borderColor: '#10b981',
            backgroundColor: gradient,
            borderWidth: 3,
            fill: true,
            tension: 0.35,
            pointBackgroundColor: '#34d399',
            pointRadius: 4,
            pointHoverRadius: 7
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              labels: { color: '#9ca3af', font: { family: 'Inter', size: 12 } }
            },
            tooltip: {
              backgroundColor: '#111827',
              borderColor: 'rgba(16, 185, 129, 0.4)',
              borderWidth: 1,
              titleColor: '#34d399',
              bodyColor: '#fff',
              callbacks: {
                label: (c) => ` Projected Price: ₹${c.parsed.y} / Quintal`
              }
            }
          },
          scales: {
            x: {
              grid: { color: 'rgba(255, 255, 255, 0.05)' },
              ticks: { color: '#9ca3af', font: { size: 11 } }
            },
            y: {
              grid: { color: 'rgba(255, 255, 255, 0.05)' },
              ticks: {
                color: '#9ca3af',
                callback: (val) => `₹${val}`
              }
            }
          }
        }
      });
    }

    async function runPrediction() {
      const crop = document.getElementById('sel-crop').value;
      const district = document.getElementById('sel-district').value;
      const data = CROP_DATA[crop] || CROP_DATA.cotton;

      // Update the repository demo scenario; no live model output is implied.
      document.getElementById('yield-value').innerText = data.yieldKg.toLocaleString();
      document.getElementById('model-conf').innerHTML = `Confidence: <strong>${data.confidence}</strong>`;
      document.getElementById('fusion-ndvi').innerText = data.ndvi;
      document.getElementById('fusion-rain').innerText = data.rain;
      document.getElementById('fusion-soil').innerText = data.soil;

      document.getElementById('val-curr-price').innerText = `₹${data.spotPrice.toLocaleString()} / Qtl`;
      document.getElementById('val-proj-price').innerText = `₹${data.forecastPrice.toLocaleString()} / Qtl (${data.change})`;

      // Advisory text
      if (currentLang === 'hi') {
        document.getElementById('yield-adv-text').innerText = data.advHi;
      } else if (currentLang === 'mr') {
        document.getElementById('yield-adv-text').innerText = data.advMr;
      } else {
        document.getElementById('yield-adv-text').innerText = data.adv;
      }

      // Update Chart
      if (priceChart) {
        priceChart.data.datasets[0].data = data.prices;
        priceChart.update();
      }
    }

    function setLanguage(lang, button) {
      currentLang = lang;
      document.querySelectorAll('.lang-btn').forEach(b => b.classList.remove('active'));
      if (button) button.classList.add('active');

      const t = translations[lang];
      document.getElementById('hero-title').innerText = t.heroTitle;
      document.getElementById('hero-subtitle').innerText = t.heroSubtitle;
      document.getElementById('card-yield-title').innerText = t.yieldTitle;
      document.getElementById('card-price-title').innerText = t.priceTitle;
      document.getElementById('card-pest-title').innerText = t.pestTitle;
      document.getElementById('card-satellite-title').innerText = t.satelliteTitle;
      document.getElementById('btn-predict-text').innerText = t.runBtn;
      document.getElementById('lbl-curr-price').innerText = t.currPrice;
      document.getElementById('lbl-proj-price').innerText = t.projPrice;

      runPrediction();
    }

    function simulateStory(cropType) {
      document.getElementById('sel-crop').value = cropType;
      if (cropType === 'soybean') {
        document.getElementById('sel-district').value = 'nagpur';
        document.getElementById('sel-mandi').value = 'nagpur';
      } else {
        document.getElementById('sel-district').value = 'yavatmal';
        document.getElementById('sel-mandi').value = 'yavatmal';
      }
      runPrediction();
    }

    async function checkApiConnection() {
      const label = document.getElementById('api-status-text');
      try {
        const response = await fetch('https://kisaan-ml-render.onrender.com/health', { signal: AbortSignal.timeout(90000) });
        if (!response.ok) throw new Error('Service unavailable');
        const health = await response.json();
        label.textContent = health.status === 'healthy' ? 'Render API connected • Demo data' : 'API unavailable • Demo data';
      } catch (_) {
        label.textContent = 'API unavailable • Demo data';
      }
    }

    // Retire the previous Flutter shell without deleting saved profiles.
    if ('serviceWorker' in navigator) navigator.serviceWorker.getRegistrations().then(registrations => Promise.all(registrations.map(r => r.unregister()))).catch(() => {});
    if ('caches' in window) caches.keys().then(keys => Promise.all(keys.filter(k => k.startsWith('flutter-')).map(k => caches.delete(k)))).catch(() => {});

    window.addEventListener('DOMContentLoaded', () => {
      initChart();
      runPrediction();
    });
