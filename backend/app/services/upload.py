"""
Serviço para gerenciar upload de arquivos

Este serviço gerencia todo o ciclo de vida dos arquivos enviados pelos usuários,
incluindo validação, armazenamento, organização e exclusão.

Funcionalidades:
- Validar tamanho e extensão de arquivos
- Salvar arquivos organizados por cliente/demanda
- Gerar nomes únicos (UUID)
- Deletar arquivos
- Gerenciar thumbnails (futuro)

Autor: DeBrief Sistema
"""
import os
import uuid
import aiofiles
from pathlib import Path
from fastapi import UploadFile, HTTPException, status
from app.core.config import settings
import logging

# Configurar logger
logger = logging.getLogger(__name__)


class UploadService:
    """
    Gerenciar upload e armazenamento de arquivos
    
    Organiza arquivos em uma estrutura hierárquica:
    uploads/{cliente_id}/{demanda_id}/{uuid}.ext
    
    Exemplo de uso:
        ```python
        upload_service = UploadService()
        file_path = await upload_service.save_file(
            file=uploaded_file,
            cliente_id="123",
            demanda_id="456"
        )
        ```
    """
    
    def __init__(self):
        """
        Inicializar serviço de upload
        
        Carrega configurações do .env e cria diretório base se não existir
        """
        self.upload_dir = Path(settings.UPLOAD_DIR)
        self.max_size = settings.MAX_UPLOAD_SIZE
        self.allowed_extensions = settings.ALLOWED_EXTENSIONS
        
        # Criar diretório base se não existir
        self.upload_dir.mkdir(parents=True, exist_ok=True)
        
        logger.info(f"UploadService inicializado (dir: {self.upload_dir})")
    
    def validate_file(self, file: UploadFile) -> None:
        """
        Validar arquivo antes de salvar
        
        Validações:
        - Tamanho máximo (padrão: 50MB)
        - Extensão permitida (pdf, jpg, jpeg, png)
        
        Args:
            file: Arquivo enviado via FastAPI
        
        Raises:
            HTTPException 413: Se arquivo muito grande
            HTTPException 400: Se extensão não permitida
        
        Exemplo:
            ```python
            try:
                upload_service.validate_file(file)
                # Arquivo válido, prosseguir com salvamento
            except HTTPException as e:
                print(f"Arquivo inválido: {e.detail}")
            ```
        """
        # Verificar se file tem tamanho
        if not hasattr(file, 'size') or file.size is None:
            # Tentar ler para obter tamanho
            file.file.seek(0, 2)  # Ir para o final
            file_size = file.file.tell()
            file.file.seek(0)  # Voltar ao início
        else:
            file_size = file.size
        
        # Verificar tamanho
        if file_size > self.max_size:
            max_mb = self.max_size / 1024 / 1024
            logger.warning(f"Arquivo muito grande: {file_size} bytes (max: {max_mb}MB)")
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"Arquivo muito grande. Máximo: {max_mb:.0f}MB"
            )
        
        # Verificar se tem nome de arquivo
        if not file.filename:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Nome do arquivo não fornecido"
            )
        
        # Verificar extensão
        ext = file.filename.split('.')[-1].lower() if '.' in file.filename else ''
        
        if not ext or ext not in self.allowed_extensions:
            logger.warning(f"Extensão não permitida: {ext}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Extensão não permitida. Permitidos: {', '.join(self.allowed_extensions)}"
            )
        
        logger.info(f"Arquivo validado: {file.filename} ({file_size} bytes)")
    
    async def save_file(
        self,
        file: UploadFile,
        cliente_id: str,
        demanda_id: str
    ) -> str:
        """
        Salvar arquivo no servidor
        
        Cria estrutura de pastas organizada e salva arquivo
        com nome único (UUID) para evitar conflitos.
        
        Args:
            file: Arquivo enviado (FastAPI UploadFile)
            cliente_id: ID do cliente (para organizar pastas)
            demanda_id: ID da demanda
        
        Returns:
            Caminho relativo do arquivo salvo
            Exemplo: "cliente123/demanda456/abc123.pdf"
        
        Raises:
            HTTPException: Se validação falhar ou erro ao salvar
        
        Exemplo:
            ```python
            file_path = await upload_service.save_file(
                file=uploaded_file,
                cliente_id="cli-123",
                demanda_id="dem-456"
            )
            # file_path = "cli-123/dem-456/uuid-123.pdf"
            ```
        """
        # Validar arquivo
        self.validate_file(file)
        
        try:
            # Criar estrutura de pastas: uploads/{cliente_id}/{demanda_id}/
            dir_path = self.upload_dir / cliente_id / demanda_id
            dir_path.mkdir(parents=True, exist_ok=True)
            
            # Gerar nome único para arquivo
            ext = file.filename.split('.')[-1]
            unique_filename = f"{uuid.uuid4()}.{ext}"
            file_path = dir_path / unique_filename
            
            logger.info(f"Salvando arquivo: {file_path}")
            
            # Salvar arquivo usando aiofiles (assíncrono)
            async with aiofiles.open(file_path, 'wb') as f:
                # Ler conteúdo do arquivo
                content = await file.read()
                # Escrever no disco
                await f.write(content)
            
            # Retornar caminho relativo (sem o diretório base)
            relative_path = f"{cliente_id}/{demanda_id}/{unique_filename}"
            
            logger.info(f"Arquivo salvo com sucesso: {relative_path}")
            return relative_path
            
        except HTTPException:
            # Re-raise validation errors
            raise
        except Exception as e:
            logger.error(f"Erro ao salvar arquivo: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Erro ao salvar arquivo: {str(e)}"
            )
    
    def delete_file(self, file_path: str) -> bool:
        """
        Deletar arquivo do servidor
        
        Args:
            file_path: Caminho relativo do arquivo (ex: "cli123/dem456/file.pdf")
        
        Returns:
            True se deletado com sucesso, False se arquivo não existe
        
        Raises:
            Exception: Se erro ao deletar
        
        Exemplo:
            ```python
            # Deletar anexo ao cancelar demanda
            for anexo in demanda.anexos:
                upload_service.delete_file(anexo.caminho)
            ```
        """
        try:
            full_path = self.upload_dir / file_path
            
            if not full_path.exists():
                logger.warning(f"Arquivo não encontrado para deletar: {file_path}")
                return False
            
            # Deletar arquivo
            full_path.unlink()
            logger.info(f"Arquivo deletado: {file_path}")
            
            # Tentar deletar pastas vazias
            try:
                parent = full_path.parent
                if parent.exists() and not any(parent.iterdir()):
                    parent.rmdir()
                    logger.info(f"Pasta vazia removida: {parent}")
            except:
                pass
            
            return True
            
        except Exception as e:
            logger.error(f"Erro ao deletar arquivo {file_path}: {e}")
            raise
    
    def get_file_info(self, file_path: str) -> dict:
        """
        Obter informações sobre um arquivo
        
        Args:
            file_path: Caminho relativo do arquivo
        
        Returns:
            Dicionário com informações do arquivo
        
        Exemplo:
            ```python
            info = upload_service.get_file_info("cli123/dem456/file.pdf")
            print(f"Tamanho: {info['size']} bytes")
            print(f"Existe: {info['exists']}")
            ```
        """
        full_path = self.upload_dir / file_path
        
        if not full_path.exists():
            return {
                'exists': False,
                'path': str(file_path)
            }
        
        stat = full_path.stat()
        
        return {
            'exists': True,
            'path': str(file_path),
            'full_path': str(full_path),
            'size': stat.st_size,
            'created': stat.st_ctime,
            'modified': stat.st_mtime,
            'extension': full_path.suffix
        }
    
    def get_allowed_extensions(self) -> list:
        """
        Obter lista de extensões permitidas
        
        Returns:
            Lista de extensões (ex: ['pdf', 'jpg', 'png'])
        """
        return self.allowed_extensions
    
    def get_max_size_mb(self) -> float:
        """
        Obter tamanho máximo permitido em MB
        
        Returns:
            Tamanho em MB
        """
        return self.max_size / 1024 / 1024

