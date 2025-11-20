"""
Utilitários gerais do sistema
Funções auxiliares para normalização, validação, etc.
"""
import unicodedata
import re


def normalizar_nome(nome: str) -> str:
    """
    Normaliza um nome removendo acentos e convertendo para minúsculo
    
    Remove:
    - Acentos (á -> a, é -> e, etc.)
    - Espaços extras
    - Caracteres especiais (mantém apenas letras, números e espaços)
    
    Args:
        nome: Nome a ser normalizado
        
    Returns:
        str: Nome normalizado
        
    Exemplos:
        >>> normalizar_nome("Secretaria de Saúde")
        'secretaria de saude'
        >>> normalizar_nome("Secretaria de Educação")
        'secretaria de educacao'
        >>> normalizar_nome("  Secretaria   de   Saúde  ")
        'secretaria de saude'
    """
    if not nome:
        return ""
    
    # Remover espaços extras e converter para minúsculo
    nome = " ".join(nome.split()).lower()
    
    # Remover acentos usando NFD (Normalization Form Decomposed)
    # e filtrar apenas caracteres não-diacríticos
    nome_normalizado = unicodedata.normalize('NFD', nome)
    nome_sem_acentos = ''.join(
        char for char in nome_normalizado
        if unicodedata.category(char) != 'Mn'  # Mn = Mark, nonspacing (acentos)
    )
    
    # Remover caracteres especiais, mantendo apenas letras, números e espaços
    nome_limpo = re.sub(r'[^a-z0-9\s]', '', nome_sem_acentos)
    
    # Remover espaços extras novamente
    nome_final = " ".join(nome_limpo.split())
    
    return nome_final


def comparar_nomes_ignorando_acentos(nome1: str, nome2: str) -> bool:
    """
    Compara dois nomes ignorando acentos e diferenças de maiúsculas/minúsculas
    
    Args:
        nome1: Primeiro nome
        nome2: Segundo nome
        
    Returns:
        bool: True se os nomes são equivalentes (ignorando acentos e case)
        
    Exemplos:
        >>> comparar_nomes_ignorando_acentos("Secretaria de Saúde", "Secretaria de Saude")
        True
        >>> comparar_nomes_ignorando_acentos("Secretaria de Educação", "secretaria de educacao")
        True
        >>> comparar_nomes_ignorando_acentos("Secretaria de Saúde", "Secretaria de Educação")
        False
    """
    return normalizar_nome(nome1) == normalizar_nome(nome2)

