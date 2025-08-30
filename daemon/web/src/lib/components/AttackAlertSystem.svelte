<script>
    import { onMount, onDestroy } from 'svelte';
    import { writable } from 'svelte/store';
    
    // Alert event interface
    interface AlertEvent {
        timestamp: string;
        event_type: string;
        message: string;
        location?: [number, number]; // [lat, lon]
    }
    
    // Store for alerts
    const alerts = writable<AlertEvent[]>([]);
    const connectionStatus = writable<string>("disconnected");
    
    let eventSource: EventSource | null = null;
    let notificationPermission = "default";
    
    // Request notification permission
    function requestNotificationPermission() {
        if (!("Notification" in window)) {
            alert("This browser does not support desktop notifications");
            return;
        }
        
        Notification.requestPermission().then(permission => {
            notificationPermission = permission;
        });
    }
    
    // Show browser notification
    function showNotification(alert: AlertEvent) {
        if (notificationPermission === "granted") {
            const notification = new Notification("Cell Attack Detected", {
                body: `${alert.event_type} severity: ${alert.message}`,
                icon: "/rayhunter_icon.png"
            });
            
            notification.onclick = () => {
                window.focus();
            };
        }
    }
    
    // Connect to SSE endpoint
    function connectToEventSource() {
        if (eventSource) {
            eventSource.close();
        }
        
        connectionStatus.set("connecting");
        eventSource = new EventSource("/api/attack-alerts");
        
        eventSource.onopen = () => {
            connectionStatus.set("connected");
        };
        
        eventSource.onmessage = (event) => {
            try {
                const alert = JSON.parse(event.data) as AlertEvent;
                
                // Add alert to store
                alerts.update(currentAlerts => {
                    // Add new alert to beginning of array
                    return [alert, ...currentAlerts];
                });
                
                // Show notification
                showNotification(alert);
                
            } catch (error) {
                console.error("Error parsing attack alert:", error);
            }
        };
        
        eventSource.onerror = () => {
            connectionStatus.set("error");
            
            // Try to reconnect after 5 seconds
            setTimeout(() => {
                connectToEventSource();
            }, 5000);
        };
    }
    
    // Format timestamp
    function formatTimestamp(timestamp: string): string {
        const date = new Date(timestamp);
        return date.toLocaleString();
    }
    
    // View area map
    function viewAreaMap(alert: AlertEvent) {
        if (alert.location) {
            const url = `https://www.google.com/maps?q=${alert.location[0]},${alert.location[1]}`;
            window.open(url, "_blank");
        } else {
            alert(`No location data available for this alert`);
        }
    }
    
    // Clear all alerts
    function clearAllAlerts() {
        alerts.set([]);
    }
    
    // Clear single alert
    function clearAlert(index: number) {
        alerts.update(currentAlerts => {
            return currentAlerts.filter((_, i) => i !== index);
        });
    }
    
    // Get severity class
    function getSeverityClass(severity: string): string {
        switch (severity.toLowerCase()) {
            case "high":
                return "alert-high";
            case "medium":
                return "alert-medium";
            case "low":
                return "alert-low";
            default:
                return "alert-info";
        }
    }
    
    // Get connection status class
    function getConnectionStatusClass(status: string): string {
        switch (status) {
            case "connected":
                return "status-connected";
            case "connecting":
                return "status-connecting";
            case "error":
                return "status-error";
            default:
                return "status-disconnected";
        }
    }
    
    onMount(() => {
        // Request notification permission
        requestNotificationPermission();
        
        // Connect to event source
        connectToEventSource();
    });
    
    onDestroy(() => {
        // Close event source
        if (eventSource) {
            eventSource.close();
        }
    });
</script>

<div class="attack-alert-system">
    <div class="alert-header">
        <h2>Cell Attack Alerts</h2>
        <div class="connection-status {$connectionStatus === 'connected' ? 'connected' : ''}">
            <span class={getConnectionStatusClass($connectionStatus)}></span>
            {$connectionStatus}
        </div>
    </div>
    
    {#if $alerts.length === 0}
        <div class="no-alerts">
            No attacks detected
        </div>
    {:else}
        <div class="alert-actions">
            <button on:click={clearAllAlerts}>Clear All</button>
        </div>
        
        <div class="alert-list">
            {#each $alerts as alert, i}
                <div class="alert-item {getSeverityClass(alert.event_type)}">
                    <div class="alert-content">
                        <div class="alert-header">
                            <span class="alert-severity">{alert.event_type}</span>
                            <span class="alert-time">{formatTimestamp(alert.timestamp)}</span>
                            <button class="close-btn" on:click={() => clearAlert(i)}>×</button>
                        </div>
                        <div class="alert-message">{alert.message}</div>
                        {#if alert.location}
                            <div class="alert-location">
                                Location: {alert.location[0].toFixed(6)}, {alert.location[1].toFixed(6)}
                            </div>
                        {/if}
                    </div>
                    <div class="alert-actions">
                        {#if alert.location}
                            <button on:click={() => viewAreaMap(alert)}>View Map</button>
                        {/if}
                    </div>
                </div>
            {/each}
        </div>
    {/if}
</div>

<style>
    .attack-alert-system {
        background-color: #1a1a1a;
        border-radius: 8px;
        padding: 16px;
        margin-bottom: 20px;
    }
    
    .alert-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 16px;
    }
    
    .alert-header h2 {
        margin: 0;
        font-size: 1.5rem;
    }
    
    .connection-status {
        display: flex;
        align-items: center;
        font-size: 0.9rem;
    }
    
    .connection-status span {
        display: inline-block;
        width: 10px;
        height: 10px;
        border-radius: 50%;
        margin-right: 8px;
    }
    
    .status-connected {
        background-color: #4CAF50;
    }
    
    .status-connecting {
        background-color: #FFC107;
    }
    
    .status-error, .status-disconnected {
        background-color: #F44336;
    }
    
    .no-alerts {
        text-align: center;
        padding: 20px;
        color: #888;
    }
    
    .alert-actions {
        display: flex;
        justify-content: flex-end;
        margin-bottom: 10px;
    }
    
    .alert-list {
        max-height: 300px;
        overflow-y: auto;
    }
    
    .alert-item {
        margin-bottom: 10px;
        padding: 12px;
        border-radius: 6px;
        background-color: #2a2a2a;
        border-left: 4px solid #888;
    }
    
    .alert-high {
        border-left-color: #F44336;
    }
    
    .alert-medium {
        border-left-color: #FF9800;
    }
    
    .alert-low {
        border-left-color: #FFC107;
    }
    
    .alert-info {
        border-left-color: #2196F3;
    }
    
    .alert-content {
        margin-bottom: 10px;
    }
    
    .alert-header {
        display: flex;
        justify-content: space-between;
        margin-bottom: 8px;
    }
    
    .alert-severity {
        font-weight: bold;
        text-transform: uppercase;
    }
    
    .alert-time {
        color: #888;
        font-size: 0.9rem;
    }
    
    .alert-message {
        margin-bottom: 8px;
    }
    
    .alert-location {
        font-size: 0.9rem;
        color: #aaa;
    }
    
    .alert-actions {
        display: flex;
        gap: 8px;
    }
    
    button {
        background-color: #333;
        color: white;
        border: none;
        padding: 6px 12px;
        border-radius: 4px;
        cursor: pointer;
        font-size: 0.9rem;
    }
    
    button:hover {
        background-color: #444;
    }
    
    button:disabled {
        background-color: #222;
        color: #666;
        cursor: not-allowed;
    }
    
    .close-btn {
        background: none;
        border: none;
        color: #888;
        font-size: 1.2rem;
        padding: 0;
        cursor: pointer;
    }
    
    .close-btn:hover {
        color: #ccc;
    }
</style>
