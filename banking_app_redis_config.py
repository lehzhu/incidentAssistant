#!/usr/bin/env python3
"""
Redis configuration for your Python banking application.
Use this configuration in your server.py and client.py files.

Note: You need to install the redis package first:
  python3 -m venv venv
  source venv/bin/activate  
  pip install redis
"""

try:
    import redis
except ImportError:
    print("❌ Redis package not installed. Please install it first:")
    print("   python3 -m venv venv")
    print("   source venv/bin/activate")
    print("   pip install redis")
    exit(1)

# Configure Redis to use database 1 (separate from incidentAssistant)
def get_redis_client():
    """
    Get a Redis client configured for the banking application.
    Uses database 1 to avoid conflicts with incidentAssistant (database 0).
    """
    return redis.Redis(
        host='localhost',
        port=6379,
        db=1,  # Use database 1 instead of default 0
        decode_responses=True  # Automatically decode strings
    )

# Example usage:
if __name__ == "__main__":
    r = get_redis_client()
    
    # Test the connection
    try:
        r.ping()
        print("✅ Connected to Redis database 1 successfully!")
        
        # Example banking operations
        r.hset("account:123", mapping={
            "account_type": "savings",
            "balance": "1000.00",
            "owner": "John Doe"
        })
        
        r.hset("account:456", mapping={
            "account_type": "checking", 
            "balance": "500.00",
            "owner": "Jane Smith"
        })
        
        print("✅ Sample banking data created in Redis database 1")
        
        # Show all keys in database 1
        keys = r.keys("*")
        print(f"📊 Keys in banking database: {keys}")
        
    except redis.ConnectionError:
        print("❌ Could not connect to Redis. Make sure Redis is running.")
    except Exception as e:
        print(f"❌ Error: {e}")
