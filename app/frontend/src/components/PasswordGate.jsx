import { useState } from 'react';

export default function PasswordGate({ children, password = 'health2026' }) {
    const [isUnlocked, setIsUnlocked] = useState(false);
    const [inputValue, setInputValue] = useState('');
    const [error, setError] = useState(false);

    const handleSubmit = (e) => {
        e.preventDefault();
        if (inputValue === password) {
            setIsUnlocked(true);
            setError(false);
        } else {
            setError(true);
            setInputValue('');
        }
    };

    if (isUnlocked) {
        return children;
    }

    return (
        <div style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 9999,
        }}>
            {/* Blurred background */}
            <div style={{
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                backdropFilter: 'blur(10px)',
                backgroundColor: 'rgba(0, 0, 0, 0.3)',
            }} />

            {/* Password form */}
            <div style={{
                position: 'relative',
                backgroundColor: 'white',
                padding: '2rem',
                borderRadius: '8px',
                boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
                minWidth: '300px',
            }}>
                <h2 style={{ marginTop: 0, marginBottom: '1.5rem', textAlign: 'center' }}>
                    Enter Password
                </h2>
                <form onSubmit={handleSubmit}>
                    <input
                        type="password"
                        value={inputValue}
                        onChange={(e) => {
                            setInputValue(e.target.value);
                            setError(false);
                        }}
                        placeholder="Password"
                        autoFocus
                        style={{
                            width: '100%',
                            padding: '0.75rem',
                            fontSize: '1rem',
                            border: error ? '2px solid #ef4444' : '1px solid #ddd',
                            borderRadius: '4px',
                            marginBottom: '1rem',
                            boxSizing: 'border-box',
                        }}
                    />
                    {error && (
                        <p style={{ color: '#ef4444', fontSize: '0.875rem', margin: '0 0 1rem 0' }}>
                            Incorrect password
                        </p>
                    )}
                    <button
                        type="submit"
                        style={{
                            width: '100%',
                            padding: '0.75rem',
                            fontSize: '1rem',
                            backgroundColor: '#3b82f6',
                            color: 'white',
                            border: 'none',
                            borderRadius: '4px',
                            cursor: 'pointer',
                            fontWeight: '500',
                        }}
                        onMouseOver={(e) => e.target.style.backgroundColor = '#2563eb'}
                        onMouseOut={(e) => e.target.style.backgroundColor = '#3b82f6'}
                    >
                        Unlock
                    </button>
                </form>
            </div>
        </div>
    );
}
